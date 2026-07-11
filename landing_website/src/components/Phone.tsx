import { forwardRef } from 'react';

interface PhoneProps {
  imageSrc?: string;
  videoSrc?: string;
  className?: string;
  style?: React.CSSProperties;
}

const Phone = forwardRef<HTMLDivElement, PhoneProps>(
  ({ imageSrc, videoSrc, className = '', style }, ref) => {
    return (
      <div
        ref={ref}
        className={`phone-frame relative ${className}`}
        style={{
          width: 'clamp(260px, 26vw, 420px)',
          aspectRatio: '9/19.5',
          ...style,
        }}
      >
        {/* Glow behind phone */}
        <div className="glow-behind" />
        
        {/* Phone screen */}
        <div 
          className="w-full h-full overflow-hidden bg-black"
          style={{ borderRadius: '44px' }}
        >
          {videoSrc ? (
            <video
              src={videoSrc}
              className="w-full h-full object-cover"
              autoPlay
              loop
              muted
              playsInline
            />
          ) : imageSrc ? (
            <img
              src={imageSrc}
              alt="App Screenshot"
              className="w-full h-full object-cover"
            />
          ) : null}
        </div>
        
        {/* Glass reflection overlay */}
        <div 
          className="absolute inset-0 pointer-events-none"
          style={{
            borderRadius: '44px',
            background: 'linear-gradient(135deg, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0) 40%, rgba(255,255,255,0) 60%, rgba(255,255,255,0.03) 100%)',
          }}
        />
      </div>
    );
  }
);

Phone.displayName = 'Phone';

export default Phone;
