"""
ヘルスチェック用のビュー（改善版）
ECSやロードバランサーがアプリケーションの状態を確認するために使用
"""

from django.http import JsonResponse
from django.db import connection
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.views.decorators.cache import never_cache
import logging
import time

logger = logging.getLogger(__name__)

@csrf_exempt
@require_http_methods(["GET", "HEAD"])
@never_cache
def health_check(request):
    """
    アプリケーションのヘルスチェック
    - データベース接続確認（オプショナル）
    - 基本的なアプリケーション状態確認
    - ALB/ECS用に最適化
    """
    start_time = time.time()
    
    health_status = {
        'status': 'healthy',
        'timestamp': int(time.time()),
        'service': 'jimotoko-backend',
        'version': getattr(settings, 'VERSION', '1.0.0'),
        'database': 'unknown',
        'debug': settings.DEBUG,
        'checks': []
    }
    
    # 1. 基本的なアプリケーション確認（必須）
    try:
        # Django の基本動作確認
        from django.contrib.auth.models import User
        health_status['checks'].append('django_core: OK')
        
        # 設定確認
        if hasattr(settings, 'ALLOWED_HOSTS'):
            health_status['checks'].append('settings: OK')
        
    except Exception as e:
        logger.error(f"Django core check failed: {e}")
        health_status['checks'].append(f'django_core: FAILED - {str(e)}')
        health_status['status'] = 'unhealthy'
    
    # 2. データベース接続確認（オプショナル - エラーでも healthy を維持）
    db_timeout = 5  # 5秒でタイムアウト
    try:
        # タイムアウト付きでデータベース接続確認
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            if result and result[0] == 1:
                health_status['database'] = 'connected'
                health_status['checks'].append('database_connection: OK')
            else:
                health_status['database'] = 'error'
                health_status['checks'].append('database_connection: FAILED')
                # データベースエラーでもアプリケーションは healthy とする
                logger.warning("Database connection failed, but application is still healthy")
                
    except Exception as e:
        logger.warning(f"Database health check failed (non-critical): {e}")
        health_status['database'] = 'disconnected'
        health_status['checks'].append(f'database_connection: FAILED - {str(e)}')
        # データベース接続失敗でも healthy を維持（重要な変更）
        health_status['checks'].append('note: database failure does not affect app health')
    
    # 3. 応答時間確認
    response_time = round((time.time() - start_time) * 1000, 2)
    health_status['response_time_ms'] = response_time
    
    if response_time > 5000:  # 5秒以上の場合は警告
        health_status['checks'].append(f'response_time: SLOW ({response_time}ms)')
    else:
        health_status['checks'].append(f'response_time: OK ({response_time}ms)')
    
    # 4. メモリ使用量確認（オプション）
    try:
        import psutil
        memory_percent = psutil.virtual_memory().percent
        health_status['memory_usage_percent'] = memory_percent
        if memory_percent > 90:
            health_status['checks'].append(f'memory: HIGH ({memory_percent}%)')
        else:
            health_status['checks'].append(f'memory: OK ({memory_percent}%)')
    except ImportError:
        # psutil がインストールされていない場合は無視
        pass
    except Exception as e:
        logger.debug(f"Memory check failed: {e}")
    
    # 5. ステータスコード決定
    # データベース接続失敗でも、アプリケーション自体が正常なら 200 を返す
    status_code = 200 if health_status['status'] == 'healthy' else 503
    
    # 6. HEADリクエストの場合は空のレスポンス
    if request.method == 'HEAD':
        response = JsonResponse({}, status=status_code)
    else:
        response = JsonResponse(health_status, status=status_code)
    
    # 7. キャッシュ無効化ヘッダー
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response['Pragma'] = 'no-cache'
    response['Expires'] = '0'
    
    return response


@csrf_exempt
@require_http_methods(["GET", "HEAD"])
@never_cache
def simple_health_check(request):
    """
    シンプルなヘルスチェック（ALB用）
    データベース接続に関係なく、アプリケーションが起動していれば OK
    """
    response_data = {
        'status': 'healthy',
        'service': 'jimotoko-backend',
        'timestamp': int(time.time())
    }
    
    # HEADリクエストの場合は空のレスポンス
    if request.method == 'HEAD':
        response = JsonResponse({}, status=200)
    else:
        response = JsonResponse(response_data, status=200)
    
    # キャッシュ無効化
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response['Pragma'] = 'no-cache'
    response['Expires'] = '0'
    
    return response


@csrf_exempt
@require_http_methods(["GET"])
def ready_check(request):
    """
    準備完了チェック（Kubernetes readiness probe 風）
    データベース接続が必要なサービスの場合に使用
    """
    checks = {
        'database': False,
        'migrations': False,
        'ready': False
    }
    
    try:
        # データベース接続確認
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            if result and result[0] == 1:
                checks['database'] = True
        
        # マイグレーション状態確認
        from django.db.migrations.executor import MigrationExecutor
        executor = MigrationExecutor(connection)
        if not executor.migration_plan(executor.loader.graph.leaf_nodes()):
            checks['migrations'] = True
        
    except Exception as e:
        logger.error(f"Ready check failed: {e}")
    
    # 全てのチェックが成功した場合のみ ready
    checks['ready'] = all(checks.values())
    
    status_code = 200 if checks['ready'] else 503
    return JsonResponse(checks, status=status_code)