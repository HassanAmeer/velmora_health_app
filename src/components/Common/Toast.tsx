import React from 'react';
import './Toast.css';

type ToastProps = {
    message: string;
    type: 'success' | 'warning' | 'danger';
};

const Toast: React.FC<ToastProps> = ({ message, type }) => {
    return (
        <div className={`toast toast-${type}`}>
            {message}
        </div>
    );
};

export default Toast;