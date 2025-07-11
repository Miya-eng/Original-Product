import SignupForm from '@/components/SignupForm';

export default function SignupPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="w-full max-w-md bg-white px-8 py-10 shadow-md">
        <h1 className="text-sm text-gray-500 mb-4">Sign Up</h1>
        <div className="text-4xl text-center font-bold font-serif mb-10">Jimotoko</div>
        <SignupForm />
      </div>
    </div>
  );
}
