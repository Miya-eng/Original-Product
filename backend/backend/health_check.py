"""
ヘルスチェック用のビュー
ECSやロードバランサーがアプリケーションの状態を確認するために使用
"""

from django.http import JsonResponse
from django.db import connection
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

def health_check(request):
    """
    アプリケーションのヘルスチェック
    - データベース接続確認
    - 基本的なアプリケーション状態確認
    """
    health_status = {
        'status': 'healthy',
        'database': 'unknown',
        'debug': settings.DEBUG,
        'checks': []
    }
    
    try:
        # データベース接続確認
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            if result and result[0] == 1:
                health_status['database'] = 'connected'
                health_status['checks'].append('database_connection: OK')
            else:
                health_status['database'] = 'error'
                health_status['checks'].append('database_connection: FAILED')
                health_status['status'] = 'unhealthy'
                
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        health_status['database'] = 'error'
        health_status['checks'].append(f'database_connection: FAILED - {str(e)}')
        health_status['status'] = 'unhealthy'
    
    # 基本的なアプリケーション確認
    try:
        from django.contrib.auth.models import User
        health_status['checks'].append('django_models: OK')
    except Exception as e:
        logger.error(f"Django models check failed: {e}")
        health_status['checks'].append(f'django_models: FAILED - {str(e)}')
        health_status['status'] = 'unhealthy'
    
    # ステータスコードを設定
    status_code = 200 if health_status['status'] == 'healthy' else 503
    
    return JsonResponse(health_status, status=status_code)