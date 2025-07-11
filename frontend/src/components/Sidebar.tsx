import { Home, Search, Plus, User } from 'lucide-react';
import Link from 'next/link';

export default function Sidebar() {
    return (
        <aside className="w-20 bg-gray-100 min-h-screen flex flex-col items-center py-8 space-y-6">
            <button className="p-2 hover:bg-gray-300 rounded">
                <Home size={32} />
            </button>
            <button className="p-2 hover:bg-gray-300 rounded">
                <Search size={32} />
            </button>
            <button className="p-2 hover:bg-gray-300 rounded">
                <Link href="/posts/new">
                    <Plus size={32} />
                </Link>
            </button>
            <div className="mt-auto mb-0">
                <button className="p-2 hover:bg-gray-300 rounded">
                    <Link href="/profile">
                        <User size={32} />
                    </Link>
                </button>
            </div>
        </aside>
    );
}
