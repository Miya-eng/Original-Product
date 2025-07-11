// src/api/auth.ts
import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api';

export const signup = async (formData: {
  username: string;
  email: string;
  password: string;
  residence_prefecture: string;
  residence_city: string;
}) => {
  const response = await axios.post(`${API_BASE_URL}/users/register/`, formData);
  return response.data;
};

export const login = async (formData: {
    email: string;
    password: string;
  }) => {
    const response = await axios.post(`${API_BASE_URL}/users/login/`, {
        username: formData.email,
        password: formData.password
    });
    return response.data; // 例: { access: "...", refresh: "..." }
  };