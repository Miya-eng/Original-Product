'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { signup } from '@/api/auth';

export default function SignupForm() {
    const router = useRouter();

    const [formData, setFormData] = useState({
        username: '',
        userId: '',
        residence_prefecture: '',
        residence_city: '',
        email: '',
        password: '',
        passwordConfirm: '',
    });

    const [error, setError] = useState('');

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (formData.password !== formData.passwordConfirm) {
            setError('パスワードが一致しません');
            return;
        }

        try {
            await signup({
                username: formData.userId || formData.username, // userIdをusernameとして使用
                email: formData.email,
                password: formData.password,
                residence_prefecture: formData.residence_prefecture,
                residence_city: formData.residence_city,
            });

            setTimeout(() => {
                router.push('/login');
            }, 1500);

        } catch (err: unknown) {
            console.error('Registration error:', err);
            
            // 詳細なエラーメッセージを表示
            if (err && typeof err === 'object' && 'response' in err) {
                const error = err as { response?: { data?: Record<string, unknown> } };
                const errorData = error.response?.data;
                console.log('Error details:', errorData);
                
                if (typeof errorData === 'string') {
                    setError(errorData);
                } else if (errorData && typeof errorData === 'object') {
                    if (Array.isArray(errorData.username)) {
                        setError(`ユーザーID: ${errorData.username[0]}`);
                    } else if (Array.isArray(errorData.email)) {
                        setError(`メールアドレス: ${errorData.email[0]}`);
                    } else if (Array.isArray(errorData.password)) {
                        setError(`パスワード: ${errorData.password[0]}`);
                    } else if (Array.isArray(errorData.residence_prefecture)) {
                        setError(`都道府県: ${errorData.residence_prefecture[0]}`);
                    } else if (Array.isArray(errorData.residence_city)) {
                        setError(`市区町村: ${errorData.residence_city[0]}`);
                    } else if (Array.isArray(errorData.non_field_errors)) {
                        setError(errorData.non_field_errors[0] as string);
                    } else {
                        setError('登録に失敗しました。入力内容を確認してください。');
                    }
                } else {
                    setError('登録に失敗しました。入力内容を確認してください。');
                }
            } else {
                setError('サーバーに接続できません。ネットワーク接続を確認してください。');
            }
        }
    };

    return (
        <>
            {error && (
                <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
                    {error}
                </div>
            )}
            <form onSubmit={handleSubmit} className="space-y-4">
                <input
                    type="text"
                    name="username"
                    placeholder="ユーザーネーム"
                    value={formData.username}
                    onChange={handleChange}
                    className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
                />
                <input
                    type="text"
                    name="userId"
                    placeholder="ユーザーID"
                    value={formData.userId}
                    onChange={handleChange}
                    className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
                />
                <input
                    type="text"
                    name="residence_prefecture"
                    placeholder="都道府県"
                    value={formData.residence_prefecture}
                    onChange={handleChange}
                    className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
                />
                <input
                    type="text"
                    name="residence_city"
                    placeholder="市区町村"
                    value={formData.residence_city}
                    onChange={handleChange}
                    className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
                />
                <input
                    type="email"
                    name="email"
                    placeholder="メールアドレス"
                    value={formData.email}
                    onChange={handleChange}
                    className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
                />
                <input
                    type="password"
                    name="password"
                    placeholder="パスワード"
                    value={formData.password}
                    onChange={handleChange}
                    className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
                />
                <input
                    type="password"
                    name="passwordConfirm"
                    placeholder="確認用パスワード"
                    value={formData.passwordConfirm}
                    onChange={handleChange}
                    className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
                />
                <button type="submit" className="w-full bg-blue-500 text-white text-lg font-semibold py-2 mt-2 hover:bg-blue-600">
                    Continue
                </button>
            </form>

            <div className="text-sm text-center mt-6">
                すでに登録済みの方は{" "}
                <Link href="/login" className="text-blue-600 hover:underline">
                    こちらからログイン
                </Link>
            </div>
        </>
    );
}
