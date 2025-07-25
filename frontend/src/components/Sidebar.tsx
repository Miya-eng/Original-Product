import { Home, Search, Plus, User } from 'lucide-react';
import Link from 'next/link';

export default function Sidebar() {
    return (
        <aside className="w-20 bg-gray-100 min-h-screen flex flex-col items-center py-8 space-y-6">
            <Link href="/home">
                <button className="p-2 hover:bg-gray-300 rounded">
                    <Home size={32} />
                </button>
            </Link>
            <Link href="/search">
                <button className="p-2 hover:bg-gray-300 rounded">
                    <Search size={32} />
                </button>
            </Link>
            <button className="p-2 hover:bg-gray-300 rounded">
                <Link href="/posts/new">
                    <Plus size={32} />
                </Link>
            </button>
            <button className="p-2 hover:bg-gray-300 rounded">
                <Link href="/profile">
                    <User size={32} />
                </Link>
            </button>
        </aside>
    );
}
