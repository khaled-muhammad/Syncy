import { useState, useEffect } from 'react';
import Phone from './components/Phone';
import './App.css';

// Core features data
const coreFeatures = [
  {
    icon: (
      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
    ),
    title: 'Watch Together',
    description: 'Sync your local media files instantly with friends over the network.',
    highlight: 'Local Sync'
  },
  {
    icon: (
      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
      </svg>
    ),
    title: 'Live Reactions',
    description: 'React in real-time with emojis and comments while watching together.',
    highlight: 'Instant feel'
  },
  {
    icon: (
      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
      </svg>
    ),
    title: 'Local First',
    description: 'No accounts or internet streaming needed. Just your files, synced perfectly.',
    highlight: 'Privacy first'
  }
];

// Social proof data
const testimonials = [
  {
    name: 'Khaled Muhammad',
    role: 'Student',
    content: 'Syncy makes syncing our local movie files so incredibly simple. It feels like we are in the same room even when we are miles apart.',
    rating: 5
  },
  {
    name: 'Malak Sabry',
    role: 'Student',
    content: 'Finally, a way to watch our local files together without the lag of screen sharing. Perfect for our movie nights!',
    rating: 5
  }
];

// Stats data
const stats = [
  { number: 'Beta', label: 'Development Stage' },
  { number: 'Fast', label: 'Local Network Sync' },
  { number: '100%', label: 'Privacy Focused' },
  { number: 'Soon', label: 'App Store Launch' }
];

// Pricing data
const pricingTiers = [
  {
    name: 'Early Bird',
    price: 'Free',
    description: 'Perfect for local movie nights with roommates.',
    features: ['Unlimited local files', 'Subtitles Supported', 'Unlimited Friends (Local)', 'No Account Required'],
    buttonText: 'Join Beta',
    popular: true
  },
  {
    name: 'Support',
    price: '$5',
    description: 'Support the open development of Syncy.',
    features: ['Dev Community Badge', 'Beta Feature Access', 'Priority Bug Reports', 'Eternal Gratitude'],
    buttonText: 'Support Dev',
    popular: false
  }
];

// Roadmap data
const roadmapItems = [
  {
    title: 'Music Sync',
    description: 'Sync your favorite music streaming services for a complete audio-visual experience.',
    status: 'Planned',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3" />
      </svg>
    )
  },
  {
    title: 'Web Streaming',
    description: 'Direct support for Netflix, Disney+, and YouTube within the Syncy player.',
    status: 'In Progress',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
      </svg>
    )
  },
  {
    title: 'Cross-Device Sync',
    description: 'Sync your local media library across all your mobile and desktop devices.',
    status: 'Coming Soon',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
      </svg>
    )
  }
];

function App() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeModal, setActiveModal] = useState<string | null>(null);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <div className="relative min-h-screen">
      {/* Premium Aurora Mesh Background */}
      <div className="fixed inset-0 z-0 overflow-hidden pointer-events-none">
        {/* Base Gradient Layer */}
        <div className="absolute inset-0 bg-[#020617]"></div>
        
        {/* Animated Aurora Blobs */}
        <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-purple-600/20 blur-[120px] rounded-full animate-blob"></div>
        <div className="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] bg-pink-600/10 blur-[150px] rounded-full animate-blob animation-delay-2000"></div>
        <div className="absolute top-[20%] right-[10%] w-[40%] h-[40%] bg-blue-600/20 blur-[100px] rounded-full animate-blob animation-delay-4000"></div>
        
        {/* Dot Grid Pattern Layer */}
        <div className="absolute inset-0 bg-dot-grid opacity-[0.15]"></div>
        
        {/* Grain/Noise Texture Layer */}
        <div className="absolute inset-0 bg-noise mix-blend-overlay"></div>

        {/* Dynamic Spotlight (Interactive feel) */}
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-[#020617] opacity-60"></div>
      </div>

      {/* Main Content (Relative for Z-index) */}
      <div className="relative z-10 w-full">
      {/* Navigation */}
      <div className="fixed top-6 left-0 right-0 z-50 flex justify-center px-4">
        <nav 
          className={`
            relative flex items-center justify-between gap-8 px-6 h-14 rounded-full border transition-all duration-500
            ${isScrolled 
              ? 'w-full max-w-2xl bg-black/40 backdrop-blur-xl border-white/10 shadow-[0_8px_32px_0_rgba(0,0,0,0.37)]' 
              : 'w-full max-w-4xl bg-white/5 backdrop-blur-md border-white/20'
            }
          `}
        >
          {/* Logo */}
          <div className="flex items-center gap-2">
            <img src="/logo.png" alt="Syncy Logo" className="w-8 h-8 object-contain" />
            <span className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white to-gray-400">
              Syncy
            </span>
          </div>
          
          {/* Desktop Links */}
          <div className="hidden md:flex items-center gap-8">
            <a href="#features" className="text-sm font-medium text-gray-300 hover:text-white transition-colors relative group">
              Features
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-purple-500 transition-all duration-300 group-hover:w-full"></span>
            </a>
            <a href="#testimonials" className="text-sm font-medium text-gray-300 hover:text-white transition-colors relative group">
              Reviews
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-purple-500 transition-all duration-300 group-hover:w-full"></span>
            </a>
            <a href="#pricing" className="text-sm font-medium text-gray-300 hover:text-white transition-colors relative group">
              Pricing
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-purple-500 transition-all duration-300 group-hover:w-full"></span>
            </a>
            <a href="#roadmap" className="text-sm font-medium text-gray-300 hover:text-white transition-colors relative group">
              Roadmap
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-purple-500 transition-all duration-300 group-hover:w-full"></span>
            </a>
          </div>

          {/* CTA / Mobile Toggle */}
          <div className="flex items-center gap-4">
            <a 
              href="https://github.com/khaled-muhammad/Syncy/releases" 
              target="_blank" 
              rel="noopener noreferrer"
              className="hidden sm:block bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white text-sm font-semibold px-5 py-2 rounded-full transition-all shadow-lg shadow-purple-600/20 active:scale-95"
            >
              Get Started
            </a>
            <button 
              className="md:hidden p-2 text-white/70 hover:text-white transition-colors"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={mobileMenuOpen ? "M6 18L18 6M6 6l12 12" : "M4 6h16M4 12h16M4 18h16"} />
              </svg>
            </button>
          </div>

          {/* Mobile menu overlay */}
          {mobileMenuOpen && (
            <div className="absolute top-full left-0 right-0 mt-4 p-4 md:hidden">
              <div className="bg-black/80 backdrop-blur-2xl border border-white/10 rounded-3xl p-6 shadow-2xl animate-in fade-in zoom-in duration-300">
                <div className="flex flex-col gap-6">
                  <a href="#features" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium text-white/80 hover:text-white transition-colors">Features</a>
                  <a href="#testimonials" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium text-white/80 hover:text-white transition-colors">Reviews</a>
                  <a href="#pricing" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium text-white/80 hover:text-white transition-colors">Pricing</a>
                  <a href="#roadmap" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium text-white/80 hover:text-white transition-colors">Roadmap</a>
                  <a 
                    href="https://github.com/khaled-muhammad/Syncy/releases" 
                    target="_blank" 
                    rel="noopener noreferrer"
                    className="w-full bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold py-4 rounded-2xl shadow-xl shadow-purple-900/40 text-center"
                  >
                    Get Beta Access
                  </a>
                </div>
              </div>
            </div>
          )}
        </nav>
      </div>

      {/* Hero Section */}
      <section className="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center">
            <h1 className="text-4xl sm:text-6xl lg:text-7xl font-bold text-white mb-6">
              Watch Together.
              <span className="block text-purple-400">Anywhere.</span>
            </h1>
            <p className="text-xl sm:text-2xl text-gray-300 mb-8 max-w-3xl mx-auto">
              Sync your local media, react in real-time, and share moments with friends over your local network. No accounts, no cloud, just your movies.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12">
              <a 
                href="https://github.com/khaled-muhammad/Syncy/releases" 
                target="_blank" 
                rel="noopener noreferrer"
                className="bg-purple-600 hover:bg-purple-700 text-white px-8 py-4 rounded-full text-lg font-semibold transition-all transform hover:scale-105 flex items-center justify-center"
              >
                Get Beta Access
              </a>
              <a href="#features" className="border border-purple-400 text-purple-400 hover:bg-purple-400 hover:text-white px-8 py-4 rounded-full text-lg font-semibold transition-all flex items-center justify-center">
                Learn More
              </a>
            </div>
          </div>
          
          <div className="flex justify-center mt-12">
            <div className="relative">
              <div className="absolute inset-0 bg-purple-500/20 blur-3xl rounded-full"></div>
              <Phone imageSrc="/hero_ui.jpg" className="relative transform hover:scale-105 transition-transform duration-300" />
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-16 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-3xl sm:text-4xl font-bold text-white mb-2">{stat.number}</div>
                <div className="text-gray-400">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-32 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-24">
            <h2 className="text-4xl sm:text-6xl font-extrabold text-white mb-6">
              Features Beyond <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">Sync.</span>
            </h2>
            <p className="text-xl text-gray-400 max-w-3xl mx-auto leading-relaxed">
              Syncy brings the movie theater experience to your home, no matter how far apart your friends are.
            </p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            {coreFeatures.map((feature, index) => (
              <div key={index} className="group relative bg-white/5 backdrop-blur-3xl rounded-[2.5rem] p-10 border border-white/10 hover:bg-white/10 transition-all duration-500 hover:-translate-y-2 comfy-glow">
                {/* Spotlight effect */}
                <div className="absolute inset-0 bg-gradient-to-br from-purple-500/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-[2.5rem]"></div>
                
                <div className="relative z-10">
                  <div className="w-16 h-16 bg-white/5 rounded-2xl flex items-center justify-center text-4xl mb-8 group-hover:scale-110 group-hover:bg-purple-500/20 transition-all duration-500 shadow-inner">
                    {feature.icon}
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-4">{feature.title}</h3>
                  <p className="text-gray-400 leading-relaxed mb-8">{feature.description}</p>
                  <div className="inline-flex items-center gap-2 bg-purple-500/10 text-purple-300 px-4 py-1.5 rounded-full text-sm font-semibold border border-purple-500/20">
                    <span className="w-1.5 h-1.5 bg-purple-400 rounded-full animate-pulse"></span>
                    {feature.highlight}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>


      {/* Demo Video Section */}
      <section id="demo" className="py-24 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col lg:flex-row items-center gap-16">
            <div className="flex-1 text-center lg:text-left">
              <h2 className="text-4xl sm:text-6xl font-extrabold text-white mb-8 tracking-tight">
                See it in <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">Action.</span>
              </h2>
              <p className="text-xl text-gray-400 mb-10 leading-relaxed max-w-2xl">
                Experience the magic of instant local-first sync. Watch how Syncy connects and synchronizes your media in real-time, zero lag, zero cloud.
              </p>
              <div className="flex flex-wrap gap-4 justify-center lg:justify-start">
                <div className="bg-white/5 border border-white/10 px-6 py-3 rounded-2xl flex items-center gap-3">
                  <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                  <span className="text-gray-300 font-medium text-sm">Real-time Performance</span>
                </div>
                <div className="bg-white/5 border border-white/10 px-6 py-3 rounded-2xl flex items-center gap-3">
                  <span className="w-2 h-2 bg-purple-500 rounded-full animate-pulse"></span>
                  <span className="text-gray-300 font-medium text-sm">Local Network Only</span>
                </div>
              </div>
            </div>
            <div className="flex-1 w-full lg:w-auto flex justify-center">
              <div className="relative group w-full max-w-3xl">
                <div className="absolute inset-x-0 -inset-y-4 bg-purple-500/20 blur-[80px] rounded-full group-hover:bg-purple-500/30 transition-all duration-500"></div>
                <div className="relative aspect-video rounded-3xl overflow-hidden border border-white/10 bg-black shadow-2xl comfy-glow transform hover:scale-[1.02] transition-transform duration-500">
                  <video
                    src="/example.mp4"
                    className="w-full h-full object-cover"
                    autoPlay
                    loop
                    muted
                    playsInline
                  />
                  {/* Glass overlay */}
                  <div className="absolute inset-0 pointer-events-none bg-gradient-to-tr from-white/5 to-transparent"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section id="testimonials" className="py-32 px-4 sm:px-6 lg:px-8 bg-white/[0.02]">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-24">
            <h2 className="text-4xl sm:text-6xl font-extrabold text-white mb-6">Loved by <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">Viewers.</span></h2>
            <p className="text-xl text-gray-400 max-w-3xl mx-auto leading-relaxed">
              Experience the future of local-first media sync with our early community.
            </p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <div key={index} className="bg-white/5 backdrop-blur-3xl rounded-[2.5rem] p-10 border border-white/10 comfy-glow hover:bg-white/10 transition-all duration-500">
                <div className="flex gap-1 mb-8">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <svg key={i} className="w-5 h-5 text-yellow-500/80 fill-current drop-shadow-[0_0_8px_rgba(234,179,8,0.3)]" viewBox="0 0 20 20">
                      <path d="M10 15l-5.878 3.09 1.123-6.545L.489 6.91l6.572-.955L10 0l2.939 5.955 6.572.955-4.756 4.635 1.123 6.545z"/>
                    </svg>
                  ))}
                </div>
                <p className="text-gray-300 mb-10 text-lg leading-relaxed italic line-clamp-4">"{testimonial.content}"</p>
                <div className="flex items-center gap-4 pt-8 border-t border-white/5">
                  <div className="w-12 h-12 rounded-full bg-gradient-to-tr from-purple-500/20 to-pink-500/20 flex items-center justify-center font-bold text-white border border-white/10">
                    {testimonial.name[0]}
                  </div>
                  <div>
                    <div className="font-bold text-white tracking-wide">{testimonial.name}</div>
                    <div className="text-gray-500 text-sm font-medium uppercase tracking-widest">{testimonial.role}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-32 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-24">
            <h2 className="text-4xl sm:text-6xl font-extrabold text-white mb-6">
              Simple, <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">Transparent</span> Pricing.
            </h2>
            <p className="text-xl text-gray-400 max-w-3xl mx-auto leading-relaxed">
              Choose the plan that fits your watch party needs.
            </p>
          </div>

          <div className="grid lg:grid-cols-3 gap-8 items-stretch">
            {pricingTiers.map((tier, index) => (
              <div 
                key={index} 
                className={`
                  relative flex flex-col p-10 rounded-[3rem] border transition-all duration-500 comfy-glow
                  ${tier.popular 
                    ? 'bg-white/10 border-purple-500/50 scale-105 z-10' 
                    : 'bg-white/5 border-white/10 hover:bg-white/10'
                  }
                `}
              >
                {tier.popular && (
                  <div className="absolute -top-5 left-1/2 -translate-x-1/2 bg-gradient-to-r from-purple-600 to-pink-600 text-white text-xs font-bold uppercase tracking-widest px-6 py-2 rounded-full shadow-lg shadow-purple-900/40">
                    Most Popular
                  </div>
                )}
                
                <div className="mb-10">
                  <h3 className="text-2xl font-bold text-white mb-2">{tier.name}</h3>
                  <div className="flex items-baseline gap-1 mb-4">
                    <span className="text-5xl font-extrabold text-white">{tier.price}</span>
                    <span className="text-gray-400 font-medium">/mo</span>
                  </div>
                  <p className="text-gray-400 text-sm leading-relaxed">{tier.description}</p>
                </div>

                <div className="flex-grow space-y-4 mb-10">
                  {tier.features.map((feature, i) => (
                    <div key={i} className="flex items-center gap-3">
                      <div className="w-5 h-5 rounded-full bg-purple-500/20 flex items-center justify-center">
                        <svg className="w-3.5 h-3.5 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                        </svg>
                      </div>
                      <span className="text-gray-300 text-sm">{feature}</span>
                    </div>
                  ))}
                </div>

                <a 
                  href="https://github.com/khaled-muhammad/Syncy/releases"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={`
                    w-full py-4 rounded-2xl font-bold transition-all duration-300 active:scale-[0.98] text-center
                    ${tier.popular 
                      ? 'bg-gradient-to-r from-purple-600 to-pink-600 text-white shadow-xl shadow-purple-900/40 hover:shadow-purple-700/60' 
                      : 'bg-white/5 border border-white/10 text-white hover:bg-white/10'
                    }
                  `}
                >
                  {tier.buttonText}
                </a>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Roadmap Section */}
      <section id="roadmap" className="py-32 px-4 sm:px-6 lg:px-8 bg-white/[0.01]">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-24">
            <h2 className="text-4xl sm:text-6xl font-extrabold text-white mb-6">
              The <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">Future</span> of Sync.
            </h2>
            <p className="text-xl text-gray-400 max-w-3xl mx-auto leading-relaxed">
              We're just getting started. Here's what's coming next to Syncy.
            </p>
          </div>

          <div className="relative">
            {/* Center Line */}
            <div className="absolute left-1/2 -translate-x-1/2 top-0 bottom-0 w-px bg-gradient-to-b from-purple-500/50 via-pink-500/50 to-transparent hidden md:block"></div>

            <div className="space-y-12">
              {roadmapItems.map((item, index) => (
                <div key={index} className={`relative flex items-center justify-between gap-8 md:gap-0 ${index % 2 === 0 ? 'md:flex-row' : 'md:flex-row-reverse'}`}>
                  {/* Timeline Dot */}
                  <div className="absolute left-1/2 -translate-x-1/2 w-4 h-4 rounded-full bg-purple-500 border-4 border-[#020617] shadow-[0_0_15px_rgba(168,85,247,0.5)] z-20 hidden md:block"></div>

                  {/* Content Card */}
                  <div className={`w-full md:w-[45%] bg-white/5 backdrop-blur-3xl p-8 rounded-[2.5rem] border border-white/10 comfy-glow hover:bg-white/10 transition-all duration-500 hover:-translate-y-1`}>
                    <div className="flex items-center gap-4 mb-4">
                      <div className="p-3 bg-purple-500/20 rounded-2xl text-purple-400">
                        {item.icon}
                      </div>
                      <div>
                        <span className="text-xs font-bold uppercase tracking-widest text-purple-500 mb-1 block">{item.status}</span>
                        <h3 className="text-xl font-bold text-white">{item.title}</h3>
                      </div>
                    </div>
                    <p className="text-gray-400 text-sm leading-relaxed">{item.description}</p>
                  </div>

                  {/* Spacer for desktop */}
                  <div className="hidden md:block w-[45%]"></div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>
      <section className="py-24 px-4 sm:px-6 lg:px-8">
        <div className="max-w-5xl mx-auto">
          <div className="relative overflow-hidden bg-white/5 backdrop-blur-3xl border border-white/10 rounded-[3rem] p-12 md:p-20 text-center shadow-2xl comfy-glow">
            {/* Internal Aurora Accents */}
            <div className="absolute top-[-20%] right-[-10%] w-80 h-80 bg-purple-600/20 blur-[100px] rounded-full animate-blob"></div>
            <div className="absolute bottom-[-20%] left-[-10%] w-80 h-80 bg-pink-600/20 blur-[100px] rounded-full animate-blob animation-delay-2000"></div>

            <div className="relative z-10">
              <h2 className="text-4xl sm:text-6xl font-extrabold text-white mb-8 tracking-tight">
                Ready to Sync <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">Your Story?</span>
              </h2>
              <p className="text-xl text-gray-300 mb-12 max-w-2xl mx-auto leading-relaxed">
                Join our early testers and experience the future of local-first media sync. No accounts required.
              </p>
              
              <div className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-12">
                <a 
                  href="https://github.com/khaled-muhammad/Syncy/releases"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="bg-gradient-to-r from-purple-600 to-pink-600 text-white px-10 py-5 rounded-full text-lg font-bold transition-all transform hover:scale-105 hover:shadow-[0_0_40px_rgba(139,92,246,0.4)] active:scale-95"
                >
                  Get Beta Access
                </a>
                <a href="#roadmap" className="bg-white/10 backdrop-blur-md border border-white/20 text-white px-10 py-5 rounded-full text-lg font-bold transition-all hover:bg-white/20 active:scale-95">
                  Roadmap
                </a>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 max-w-2xl mx-auto pt-8 border-t border-white/10">
                <div className="flex items-center justify-center gap-2 text-gray-400">
                  <span className="text-purple-500 font-bold text-xl">✓</span>
                  <span className="text-sm font-medium">100% Free Beta</span>
                </div>
                <div className="flex items-center justify-center gap-2 text-gray-400">
                  <span className="text-purple-500 font-bold text-xl">✓</span>
                  <span className="text-sm font-medium">Local First</span>
                </div>
                <div className="flex items-center justify-center gap-2 text-gray-400">
                  <span className="text-purple-500 font-bold text-xl">✓</span>
                  <span className="text-sm font-medium">No Account Needed</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Simple Footer */}
      <footer className="py-20 px-6">
        <div className="max-w-4xl mx-auto flex flex-col items-center text-center gap-8">
          <div className="flex items-center gap-2">
            <img src="/logo.png" alt="Syncy Logo" className="w-8 h-8 object-contain" />
            <span className="text-xl font-bold text-white">Syncy</span>
          </div>

          <div className="flex flex-wrap justify-center gap-6 md:gap-10">
            <a href="#features" className="text-gray-400 hover:text-white transition-colors text-sm font-medium">Features</a>
            <a href="#testimonials" className="text-gray-400 hover:text-white transition-colors text-sm font-medium">Reviews</a>
            <a href="#pricing" className="text-gray-400 hover:text-white transition-colors text-sm font-medium">Pricing</a>
            <button onClick={() => setActiveModal('privacy')} className="text-gray-400 hover:text-white transition-colors text-sm font-medium">Privacy</button>
            <button onClick={() => setActiveModal('terms')} className="text-gray-400 hover:text-white transition-colors text-sm font-medium">Terms</button>
          </div>

          <div className="text-gray-600 text-xs">
            © 2026 Syncy. All rights reserved.
          </div>
        </div>
      </footer>

      {/* Modals Rendering */}
      {activeModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-xl" onClick={() => setActiveModal(null)}></div>
          <div className="relative w-full max-w-2xl bg-slate-900/90 backdrop-blur-2xl border border-white/10 rounded-[3rem] p-10 md:p-16 shadow-2xl overflow-y-auto max-h-[80vh] animate-in fade-in zoom-in duration-300">
            <button 
              onClick={() => setActiveModal(null)}
              className="absolute top-8 right-8 w-12 h-12 rounded-full bg-white/5 flex items-center justify-center text-white/50 hover:text-white hover:bg-white/10 transition-all border border-white/10"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            
            <h2 className="text-3xl font-bold text-white mb-8 capitalize">{activeModal} Policy</h2>
            <div className="prose prose-invert prose-purple max-w-none text-gray-400 space-y-6">
              <p className="leading-relaxed">
                At Syncy, we believe in radical transparency. This {activeModal} document outlines how we operate and our commitment to your viewing experience.
              </p>
              <h3 className="text-white text-xl font-bold mt-8">1. Our Commitment</h3>
              <p>We prioritize your privacy and experience above all else. Our sync technology is designed to be as non-intrusive as possible while delivering perfect synchronization.</p>
              <h3 className="text-white text-xl font-bold mt-8">2. Data Usage</h3>
              <p>Any data collected is used solely to improve the synchronization quality and provide you with a smoother watch party experience. We do not sell your data to third parties.</p>
              <h3 className="text-white text-xl font-bold mt-8">3. Platform Integration</h3>
              <p>Our integration with third-party streaming platforms follows all local and international laws to ensure a safe and legal viewing environment for you and your friends.</p>
            </div>
            <div className="mt-12 pt-8 border-t border-white/5 text-center">
              <button 
                onClick={() => setActiveModal(null)}
                className="bg-purple-600 hover:bg-purple-500 text-white font-bold px-10 py-3 rounded-2xl transition-all"
              >
                Got it
              </button>
            </div>
          </div>
        </div>
      )}
      </div>
    </div>
  );
}

export default App;
