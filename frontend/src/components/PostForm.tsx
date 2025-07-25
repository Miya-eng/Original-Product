'use client';

import { useRef, useEffect, useState } from 'react';
import Script from 'next/script';
import Image from 'next/image';
import { createPost } from '@/api/posts';
import { Camera, MapPin, X } from 'lucide-react';
import { useRouter } from 'next/navigation';

interface GooglePlace {
    name?: string;
    geometry?: {
        location: GoogleLatLng;
    };
}

interface GoogleMap {
    setCenter: (location: GoogleLatLng) => void;
}

interface GoogleMarker {
    setPosition: (location: GoogleLatLng) => void;
}

interface GoogleLatLng {
    lat(): number;
    lng(): number;
}

interface GoogleAutocompleteOptions {
    types?: string[];
    componentRestrictions?: { country: string };
}

interface GoogleMapOptions {
    center: GoogleLatLng;
    zoom: number;
}

interface GoogleMarkerOptions {
    map: GoogleMap;
    position: GoogleLatLng;
}

declare global {
    interface Window {
        google: {
            maps: {
                places: {
                    Autocomplete: new (input: HTMLInputElement, options?: GoogleAutocompleteOptions) => {
                        addListener: (event: string, callback: () => void) => void;
                        getPlace: () => GooglePlace;
                    };
                };
                Map: new (element: HTMLElement, options?: GoogleMapOptions) => GoogleMap;
                Marker: new (options?: GoogleMarkerOptions) => GoogleMarker;
            };
        };
    }
}

export default function PostForm() {
    const router = useRouter();
    const inputRef = useRef<HTMLInputElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [placeResult, setPlaceResult] = useState<GooglePlace | null>(null);
    const [map, setMap] = useState<GoogleMap | null>(null);
    const [marker, setMarker] = useState<GoogleMarker | null>(null);
    const [imageFile, setImageFile] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [isGoogleLoaded, setIsGoogleLoaded] = useState(false);

    // Google Maps APIの読み込み状態を監視
    useEffect(() => {
        const checkGoogleMaps = () => {
            if (window.google && window.google.maps) {
                setIsGoogleLoaded(true);
            }
        };
        
        // 初回チェック
        checkGoogleMaps();
        
        // まだ読み込まれていない場合は定期的にチェック
        if (!isGoogleLoaded) {
            const interval = setInterval(checkGoogleMaps, 100);
            return () => clearInterval(interval);
        }
    }, [isGoogleLoaded]);

    // Autocomplete初期化
    useEffect(() => {
        if (!isGoogleLoaded || !inputRef.current) return;

        const autocomplete = new window.google.maps.places.Autocomplete(inputRef.current, {
            types: ['establishment', 'geocode'],
            componentRestrictions: { country: 'jp' }
        });

        autocomplete.addListener('place_changed', () => {
            const place = autocomplete.getPlace();
            setPlaceResult(place);
            // 入力欄には選択した名称（スポット名）が自動で入る
            inputRef.current!.value = place.name || '';
        });
    }, [isGoogleLoaded]);

    // Map表示・ピン更新
    useEffect(() => {
        if (!isGoogleLoaded) return;

        if (!map && placeResult && placeResult.geometry) {
            const mapElement = document.getElementById('map');
            if (!mapElement) return;
            
            const newMap = new window.google.maps.Map(mapElement, {
                center: placeResult.geometry.location,
                zoom: 16,
            });
            const newMarker = new window.google.maps.Marker({
                map: newMap,
                position: placeResult.geometry.location,
            });
            setMap(newMap);
            setMarker(newMarker);
        }

        if (map && marker && placeResult && placeResult.geometry) {
            map.setCenter(placeResult.geometry.location);
            marker.setPosition(placeResult.geometry.location);
        }
    }, [placeResult, map, marker, isGoogleLoaded]);

    // 画像選択ハンドラー
    const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            // ファイルサイズチェック（5MB以下）
            if (file.size > 5 * 1024 * 1024) {
                setError('画像は5MB以下にしてください');
                return;
            }
            
            setImageFile(file);
            const reader = new FileReader();
            reader.onload = (e) => {
                setImagePreview(e.target?.result as string);
            };
            reader.readAsDataURL(file);
            setError(null);
        }
    };

    // 画像削除
    const removeImage = () => {
        setImageFile(null);
        setImagePreview(null);
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        
        if (!placeResult || !placeResult.geometry) {
            setError('スポットの場所を選択してください');
            return;
        }
        
        setIsSubmitting(true);
        setError(null);
        
        const lat = placeResult.geometry.location.lat();
        const lng = placeResult.geometry.location.lng();

        try {
            const token = localStorage.getItem('accessToken');
            if (!token) {
                router.push('/login');
                return;
            }

            const formData = new FormData();
            formData.append('title', title);
            formData.append('body', body);
            formData.append('latitude', lat.toString());
            formData.append('longitude', lng.toString());
            
            if (imageFile) {
                formData.append('image', imageFile);
            }

            await createPost(formData, token);
            router.push('/home');
        } catch (err: unknown) {
            if (err && typeof err === 'object' && 'response' in err) {
                const error = err as { response?: { data?: { non_field_errors?: string[]; [key: string]: unknown } } };
                if (error.response?.data) {
                    const errorData = error.response.data;
                    if (errorData.non_field_errors && errorData.non_field_errors.length > 0) {
                        setError(errorData.non_field_errors[0]);
                    } else {
                        const firstError = Object.values(errorData)[0];
                        setError(Array.isArray(firstError) ? String(firstError[0]) : String(firstError));
                    }
                } else {
                    setError('投稿に失敗しました。もう一度お試しください。');
                }
            } else {
                setError('投稿に失敗しました。もう一度お試しください。');
            }
            console.error(err);
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <>
            <Script
                src={`https://maps.googleapis.com/maps/api/js?key=${process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY}&libraries=places`}
                strategy="afterInteractive"
                onLoad={() => setIsGoogleLoaded(true)}
            />
            <div className="max-w-2xl mx-auto p-4">
                <h1 className="text-2xl font-bold mb-6">新規投稿</h1>
                
                {error && (
                    <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className="block text-sm font-medium mb-1">タイトル</label>
                        <input
                            type="text"
                            placeholder="例: お気に入りのカフェ"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            required
                            className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium mb-1">説明</label>
                        <textarea
                            placeholder="このスポットの魅力を教えてください"
                            value={body}
                            onChange={e => setBody(e.target.value)}
                            required
                            rows={4}
                            className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium mb-1">
                            <MapPin className="inline w-4 h-4 mr-1" />
                            場所を検索
                        </label>
                        <input
                            ref={inputRef}
                            type="text"
                            placeholder="スポット名または住所で検索"
                            className="w-full p-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                            autoComplete="off"
                            disabled={!isGoogleLoaded}
                        />
                        {!isGoogleLoaded && (
                            <p className="text-sm text-gray-500 mt-1">マップを読み込み中...</p>
                        )}
                    </div>

                    {/* 地図表示 */}
                    <div id="map" className="w-full h-64 bg-gray-200 rounded-lg border border-gray-300" />

                    {/* 画像アップロード */}
                    <div>
                        <label className="block text-sm font-medium mb-1">
                            <Camera className="inline w-4 h-4 mr-1" />
                            写真を追加
                        </label>
                        
                        {!imagePreview ? (
                            <div
                                onClick={() => fileInputRef.current?.click()}
                                className="w-full h-32 border-2 border-dashed border-gray-300 rounded-lg flex items-center justify-center cursor-pointer hover:border-gray-400 transition-colors"
                            >
                                <div className="text-center">
                                    <Camera className="mx-auto w-8 h-8 text-gray-400" />
                                    <p className="mt-2 text-sm text-gray-500">クリックして写真を選択</p>
                                </div>
                            </div>
                        ) : (
                            <div className="relative">
                                <Image
                                    src={imagePreview}
                                    alt="プレビュー"
                                    width={400}
                                    height={256}
                                    className="w-full h-64 object-cover rounded-lg"
                                />
                                <button
                                    type="button"
                                    onClick={removeImage}
                                    className="absolute top-2 right-2 bg-black bg-opacity-50 text-white p-1 rounded-full hover:bg-opacity-70"
                                >
                                    <X className="w-5 h-5" />
                                </button>
                            </div>
                        )}
                        
                        <input
                            ref={fileInputRef}
                            type="file"
                            accept="image/*"
                            onChange={handleImageChange}
                            className="hidden"
                        />
                    </div>

                    <button
                        type="submit"
                        disabled={isSubmitting}
                        className={`w-full py-3 rounded-lg font-medium transition-colors ${
                            isSubmitting
                                ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                                : 'bg-blue-600 text-white hover:bg-blue-700'
                        }`}
                    >
                        {isSubmitting ? '投稿中...' : '投稿する'}
                    </button>
                </form>
            </div>
        </>
    );
}