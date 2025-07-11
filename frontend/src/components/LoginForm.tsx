'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { login } from '@/api/auth';

export default function LoginForm() {
    const router = useRouter();

    const [formData, setFormData] = useState({
        email: '',
        password: '',
    });
    const [message, setMessage] = useState({ error: '', success: '' });

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const res = await login(formData);
            localStorage.setItem('accessToken', res.access); // または context で管理
            setMessage({ success: 'ログイン成功！', error: '' });

            setTimeout(() => {
                router.push('/home');
            }, 1500);

        } catch (err) {
            console.error(err);
            setMessage({ success: '', error: 'メールアドレスまたはパスワードが正しくありません。' });
        }
    };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <input
                type="email"
                name="email"
                placeholder="メールアドレス"
                value={formData.email}
                onChange={handleChange}
                required
                className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
            />
            <input
                type="password"
                name="password"
                placeholder="パスワード"
                value={formData.password}
                onChange={handleChange}
                required
                className="w-full p-3 bg-gray-100 text-sm placeholder-gray-500"
            />
            <button type="submit" className="w-full bg-blue-500 text-white text-lg font-semibold py-2 mt-2 hover:bg-blue-600">
                Continue
            </button>
            {message.error && <p className="text-red-500 text-sm">{message.error}</p>}
            {message.success && <p className="text-green-500 text-sm">{message.success}</p>}
        </form>
    );
}
