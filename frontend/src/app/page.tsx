import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-4xl mx-auto text-center">
          {/* ヘッダー */}
          <div className="mb-12">
            <h1 className="text-5xl font-bold text-gray-900 mb-4">
              Jimotoko
            </h1>
            <p className="text-xl text-gray-600 mb-8">
              あなたの地元の魅力を発見・シェアしよう
            </p>
          </div>

          {/* アプリケーションの紹介 */}
          <div className="bg-white rounded-xl shadow-lg p-8 mb-12">
            <h2 className="text-2xl font-semibold text-gray-900 mb-6">
              Jimotokoでできること
            </h2>
            
            <div className="grid md:grid-cols-3 gap-6 mb-8">
              <div className="text-center">
                <div className="bg-blue-100 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">地元スポット発見</h3>
                <p className="text-gray-600">
                  あなたの住んでいる地域の隠れた魅力的なスポットを発見できます
                </p>
              </div>
              
              <div className="text-center">
                <div className="bg-green-100 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">投稿・シェア</h3>
                <p className="text-gray-600">
                  お気に入りの場所を写真と一緒にシェアして、地元の魅力を発信
                </p>
              </div>
              
              <div className="text-center">
                <div className="bg-purple-100 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">地域コミュニティ</h3>
                <p className="text-gray-600">
                  同じ地域の住民と交流し、地域の情報を共有できます
                </p>
              </div>
            </div>
          </div>

          {/* 使い方の説明 */}
          <div className="bg-white rounded-xl shadow-lg p-8 mb-12">
            <h2 className="text-2xl font-semibold text-gray-900 mb-6">
              使い方は簡単！
            </h2>
            
            <div className="space-y-6 text-left max-w-2xl mx-auto">
              <div className="flex items-start space-x-4">
                <div className="bg-blue-500 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold text-sm">1</div>
                <div>
                  <h4 className="font-medium text-gray-900">アカウント作成</h4>
                  <p className="text-gray-600">メールアドレスとお住まいの地域を登録</p>
                </div>
              </div>
              
              <div className="flex items-start space-x-4">
                <div className="bg-blue-500 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold text-sm">2</div>
                <div>
                  <h4 className="font-medium text-gray-900">地元の投稿を閲覧</h4>
                  <p className="text-gray-600">あなたの地域の投稿を見て、新しいスポットを発見</p>
                </div>
              </div>
              
              <div className="flex items-start space-x-4">
                <div className="bg-blue-500 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold text-sm">3</div>
                <div>
                  <h4 className="font-medium text-gray-900">お気に入りの場所を投稿</h4>
                  <p className="text-gray-600">写真と説明文で、あなたのおすすめスポットをシェア</p>
                </div>
              </div>
              
              <div className="flex items-start space-x-4">
                <div className="bg-blue-500 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold text-sm">4</div>
                <div>
                  <h4 className="font-medium text-gray-900">コミュニティに参加</h4>
                  <p className="text-gray-600">いいねやコメントで地域の仲間とつながろう</p>
                </div>
              </div>
            </div>
          </div>

          {/* CTA */}
          <div className="space-y-4">
            <Link 
              href="/signup"
              className="inline-block bg-blue-600 text-white px-8 py-4 rounded-lg font-semibold text-lg hover:bg-blue-700 transition-colors"
            >
              今すぐ始める - 無料でサインアップ
            </Link>
            
            <div className="text-gray-600">
              すでにアカウントをお持ちの方は{' '}
              <Link href="/login" className="text-blue-600 hover:text-blue-700 font-medium">
                ログイン
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
