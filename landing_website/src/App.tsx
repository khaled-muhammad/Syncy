import { useEffect, useState } from 'react';
import {
  ArrowRight,
  ArrowUpRight,
  Check,
  Download,
  FolderOpen,
  Gauge,
  Github,
  Heart,
  Menu,
  MessageCircle,
  Monitor,
  Play,
  Radio,
  RefreshCw,
  Search,
  ShieldCheck,
  Smartphone,
  Subtitles,
  Wifi,
  X,
  Zap,
} from 'lucide-react';
import './App.css';

const repoUrl = 'https://github.com/khaled-muhammad/Syncy';
const latestReleaseUrl = `${repoUrl}/releases/latest`;
const releaseApiUrl =
  'https://api.github.com/repos/khaled-muhammad/Syncy/releases/latest';
const androidFallback = `${latestReleaseUrl}/download/app-universal.apk`;
const windowsFallback = `${latestReleaseUrl}/download/syncy-windows-release.zip`;

type ReleaseAsset = {
  name: string;
  browser_download_url: string;
};

type ReleaseResponse = {
  tag_name: string;
  html_url: string;
  published_at: string;
  assets: ReleaseAsset[];
};

type LatestRelease = {
  version: string;
  releaseUrl: string;
  publishedAt?: string;
  androidUrl: string;
  windowsUrl: string;
};

const defaultRelease: LatestRelease = {
  version: 'Latest',
  releaseUrl: latestReleaseUrl,
  androidUrl: androidFallback,
  windowsUrl: windowsFallback,
};

const features = [
  {
    icon: Radio,
    title: 'Authoritative playback',
    text: 'Revisioned play, pause, and seek commands keep every participant on the newest room state.',
    accent: 'violet',
  },
  {
    icon: Wifi,
    title: 'Direct PC streaming',
    text: 'Pair Android with Windows over your LAN and stream the original file with responsive seeking.',
    accent: 'blue',
  },
  {
    icon: FolderOpen,
    title: 'Desktop media library',
    text: 'Index nested folders, generate thumbnails, search, and play broad desktop formats.',
    accent: 'magenta',
  },
  {
    icon: MessageCircle,
    title: 'Room conversation',
    text: 'Chat history, typing presence, and participant status stay beside the movie.',
    accent: 'blue',
  },
  {
    icon: Heart,
    title: 'In-player reactions',
    text: 'Send lightweight reactions that land over the moment without interrupting playback.',
    accent: 'magenta',
  },
  {
    icon: Subtitles,
    title: 'Subtitle timing',
    text: 'Load SRT or VTT files and correct track timing with an adjustable subtitle delay.',
    accent: 'violet',
  },
  {
    icon: Search,
    title: 'Fast media discovery',
    text: 'Thumbnails, folders, and search keep large local collections easy to navigate.',
    accent: 'magenta',
  },
  {
    icon: Gauge,
    title: 'Serious player controls',
    text: 'Fullscreen, double-tap seeking, keyboard control, and speeds from 0.25x to 10x.',
    accent: 'blue',
  },
  {
    icon: ShieldCheck,
    title: 'Guest-first rooms',
    text: 'Create or join with a display name. Media stays on your devices or private network.',
    accent: 'violet',
  },
];

function findAsset(
  assets: ReleaseAsset[],
  predicate: (name: string) => boolean,
  fallback: string,
) {
  return (
    assets.find((asset) => predicate(asset.name.toLowerCase()))
      ?.browser_download_url ?? fallback
  );
}

function formatDate(value?: string) {
  if (!value) return 'Latest stable build';
  return new Intl.DateTimeFormat('en', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(value));
}

function App() {
  const [release, setRelease] = useState(defaultRelease);
  const [menuOpen, setMenuOpen] = useState(false);
  const [headerCompact, setHeaderCompact] = useState(false);

  useEffect(() => {
    const controller = new AbortController();
    fetch(releaseApiUrl, {
      signal: controller.signal,
      headers: { Accept: 'application/vnd.github+json' },
    })
      .then((response) => {
        if (!response.ok) throw new Error('Could not load the latest release');
        return response.json() as Promise<ReleaseResponse>;
      })
      .then((data) => {
        setRelease({
          version: data.tag_name,
          releaseUrl: data.html_url,
          publishedAt: data.published_at,
          androidUrl: findAsset(
            data.assets,
            (name) => name === 'app-universal.apk',
            androidFallback,
          ),
          windowsUrl: findAsset(
            data.assets,
            (name) => name === 'syncy-windows-release.zip',
            windowsFallback,
          ),
        });
      })
      .catch((error: unknown) => {
        if (error instanceof DOMException && error.name === 'AbortError') return;
      });
    return () => controller.abort();
  }, []);

  useEffect(() => {
    const handleScroll = () => setHeaderCompact(window.scrollY > 24);
    handleScroll();
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => {
    document.body.style.overflow = menuOpen ? 'hidden' : '';
    return () => {
      document.body.style.overflow = '';
    };
  }, [menuOpen]);

  const closeMenu = () => setMenuOpen(false);

  return (
    <div className="site-shell">
      <header className={`site-header${headerCompact ? ' is-compact' : ''}`}>
        <div className="header-inner">
          <a className="brand" href="#top" aria-label="Syncy home">
            <img src="/logo.png" alt="" />
            <span>Syncy</span>
          </a>

          <nav className="desktop-nav" aria-label="Primary navigation">
            <a href="#overview">Overview</a>
            <a href="#features">Features</a>
            <a href="#lan">PC streaming</a>
            <a href="#downloads">Downloads</a>
          </nav>

          <div className="header-actions">
            <a
              className="icon-button"
              href={repoUrl}
              target="_blank"
              rel="noreferrer"
              aria-label="View Syncy on GitHub"
              title="View Syncy on GitHub"
            >
              <Github size={19} />
            </a>
            <a className="header-download" href="#downloads">
              <Download size={17} />
              Get Syncy
            </a>
            <button
              className="menu-button"
              type="button"
              aria-label={menuOpen ? 'Close navigation' : 'Open navigation'}
              aria-expanded={menuOpen}
              onClick={() => setMenuOpen((open) => !open)}
            >
              {menuOpen ? <X size={21} /> : <Menu size={21} />}
            </button>
          </div>
        </div>

        <nav
          className={`mobile-nav${menuOpen ? ' is-open' : ''}`}
          aria-label="Mobile navigation"
        >
          <div className="mobile-nav-status">
            <span className="live-dot" />
            {release.version} available
          </div>
          <a href="#overview" onClick={closeMenu}>
            Overview <ArrowRight size={18} />
          </a>
          <a href="#features" onClick={closeMenu}>
            Features <ArrowRight size={18} />
          </a>
          <a href="#lan" onClick={closeMenu}>
            PC streaming <ArrowRight size={18} />
          </a>
          <a href="#downloads" onClick={closeMenu}>
            Downloads <ArrowRight size={18} />
          </a>
          <a href={repoUrl} target="_blank" rel="noreferrer">
            GitHub <ArrowUpRight size={18} />
          </a>
        </nav>
      </header>

      <main>
        <section className="hero" id="top">
          <video
            className="hero-media"
            src="/example.mp4"
            poster="/hero_ui.jpg"
            autoPlay
            loop
            muted
            playsInline
            preload="metadata"
          />
          <div className="hero-shade" />
          <div className="hero-grid" aria-hidden="true" />

          <div className="hero-content page-width">
            <div className="release-kicker">
              <span className="live-dot" />
              {release.version} / Android and Windows
            </div>
            <h1>Syncy</h1>
            <p className="hero-lead">
              Your videos. Your people.
              <br />
              One shared timeline.
            </p>
            <p className="hero-detail">
              Precise room playback, conversation, subtitles, reactions, and
              direct PC-to-phone streaming for the media you already own.
            </p>
            <div className="hero-actions">
              <a className="button primary" href="#downloads">
                Download Syncy
                <Download size={18} />
              </a>
              <a
                className="button secondary"
                href={repoUrl}
                target="_blank"
                rel="noreferrer"
              >
                <Github size={18} />
                View source
              </a>
            </div>
          </div>

          <div className="hero-rail">
            <div className="page-width hero-rail-inner">
              <span>
                <strong>01</strong>
                Room playback
              </span>
              <span>
                <strong>02</strong>
                Local-first media
              </span>
              <span>
                <strong>03</strong>
                Private LAN streaming
              </span>
            </div>
          </div>
        </section>

        <section className="release-section" id="downloads">
          <div className="page-width release-layout">
            <div className="release-copy">
              <span className="section-label">Latest release</span>
              <h2>Ready for both screens.</h2>
              <p>
                {release.version} / {formatDate(release.publishedAt)}
              </p>
            </div>

            <div className="release-options">
              <a
                className="release-option"
                href={release.androidUrl}
                target="_blank"
                rel="noreferrer"
              >
                <span className="platform-icon android">
                  <Smartphone size={22} />
                </span>
                <span className="release-option-copy">
                  <small>Mobile</small>
                  <strong>Android</strong>
                  <span>Universal APK / Android 5.0+</span>
                </span>
                <Download size={20} />
              </a>
              <a
                className="release-option"
                href={release.windowsUrl}
                target="_blank"
                rel="noreferrer"
              >
                <span className="platform-icon windows">
                  <Monitor size={22} />
                </span>
                <span className="release-option-copy">
                  <small>Desktop</small>
                  <strong>Windows</strong>
                  <span>64-bit portable ZIP</span>
                </span>
                <Download size={20} />
              </a>
            </div>
          </div>
        </section>

        <section className="overview-section" id="overview">
          <div className="page-width">
            <div className="section-heading">
              <div>
                <span className="section-label">The shared room</span>
                <h2>Same movie. Same moment. Every screen.</h2>
              </div>
              <p>
                Syncy treats playback as shared state, not a collection of
                loosely connected buttons. Everyone sees the latest room
                command, whether they stayed in the app or just returned.
              </p>
            </div>

            <div className="product-stage">
              <div className="product-screen">
                <img src="/hero_ui.jpg" alt="Syncy Android media library" />
                <div className="screen-caption">
                  <span>Android library</span>
                  <strong>Media stays local</strong>
                </div>
              </div>

              <div className="room-state">
                <div className="room-state-topline">
                  <span>ROOM / J7MK2Q</span>
                  <span className="state-live">
                    <span className="live-dot" /> LIVE
                  </span>
                </div>
                <div className="now-playing">
                  <span>NOW PLAYING</span>
                  <strong>Shared timeline</strong>
                  <p>01:22:16 / 02:04:38</p>
                </div>
                <div className="timeline">
                  <span />
                  <i />
                </div>
                <div className="state-members">
                  <span>
                    <Monitor size={19} />
                    Host
                    <strong>Synced</strong>
                  </span>
                  <span>
                    <Smartphone size={19} />
                    Android
                    <strong>Synced</strong>
                  </span>
                </div>
                <div className="state-note">
                  <RefreshCw size={19} />
                  <span>
                    <strong>Lifecycle recovery</strong>
                    Reconciles after split screen and system UI transitions.
                  </span>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className="feature-section" id="features">
          <div className="page-width">
            <div className="section-heading feature-heading">
              <div>
                <span className="section-label">Everything in the room</span>
                <h2>A complete local watch experience.</h2>
              </div>
              <p>
                Built around the details that make long sessions feel
                dependable on both desktop and mobile.
              </p>
            </div>

            <div className="feature-grid">
              {features.map(({ icon: Icon, title, text, accent }, index) => (
                <article className={`feature-item accent-${accent}`} key={title}>
                  <div className="feature-topline">
                    <Icon size={24} strokeWidth={1.8} />
                    <span>{String(index + 1).padStart(2, '0')}</span>
                  </div>
                  <h3>{title}</h3>
                  <p>{text}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="lan-section" id="lan">
          <div className="page-width lan-layout">
            <div className="lan-copy">
              <span className="section-label">Windows to Android</span>
              <h2>Your desktop library, available on the couch.</h2>
              <p>
                Pair once over your private network. Browse indexed folders on
                Android and stream the original source without uploading a
                cloud copy.
              </p>
              <ul>
                <li>
                  <Check size={18} /> Six-digit pairing and trusted devices
                </li>
                <li>
                  <Check size={18} /> Nested folders and video thumbnails
                </li>
                <li>
                  <Check size={18} /> HTTP range support for precise seeking
                </li>
              </ul>
            </div>

            <div className="connection-map" aria-label="Windows to Android flow">
              <div className="device-node">
                <span className="device-icon">
                  <Monitor />
                </span>
                <span>
                  <small>SOURCE</small>
                  <strong>Windows PC</strong>
                </span>
              </div>
              <div className="connection-flow">
                <span />
                <div>
                  <Wifi size={18} />
                  PRIVATE LAN
                </div>
              </div>
              <div className="device-node">
                <span className="device-icon">
                  <Smartphone />
                </span>
                <span>
                  <small>PLAYER</small>
                  <strong>Android</strong>
                </span>
              </div>
            </div>
          </div>
        </section>

        <section className="reliability-section">
          <div className="page-width reliability-layout">
            <div className="reliability-copy">
              <span className="section-label">Reliable by design</span>
              <h2>The newest command wins. Every time.</h2>
              <p>
                Playback is revisioned on the backend and applied in order on
                every client. Reconnects and Android lifecycle transitions
                recover against the room instead of guessing.
              </p>
              <div className="reliability-points">
                <span>
                  <Zap size={18} /> Millisecond positions
                </span>
                <span>
                  <RefreshCw size={18} /> Resume reconciliation
                </span>
                <span>
                  <ShieldCheck size={18} /> Stale command rejection
                </span>
              </div>
            </div>

            <div className="revision-panel">
              <div className="revision-header">
                <span>ROOM STATE</span>
                <strong>REV 184</strong>
              </div>
              <div className="revision-event">
                <span>184</span>
                <div>
                  <strong>Pause / 01:22:16.408</strong>
                  <small>Applied to 2 participants</small>
                </div>
                <Check size={18} />
              </div>
              <div className="revision-event muted-event">
                <span>183</span>
                <div>
                  <strong>Seek / 01:22:14.902</strong>
                  <small>Superseded by revision 184</small>
                </div>
                <RefreshCw size={18} />
              </div>
              <div className="revision-footer">
                <span className="live-dot" />
                All participants synchronized
              </div>
            </div>
          </div>
        </section>

        <section className="room-section">
          <div className="room-media">
            <img src="/hero_ui.jpg" alt="Syncy local media library" />
            <div className="room-media-shade" />
            <div className="room-media-copy page-width">
              <span className="section-label">Inside the room</span>
              <h2>Keep the movie central. Keep everyone present.</h2>
              <div className="room-capabilities">
                <span>
                  <MessageCircle size={20} />
                  Live chat
                </span>
                <span>
                  <Heart size={20} />
                  Reactions
                </span>
                <span>
                  <Subtitles size={20} />
                  Subtitle timing
                </span>
                <span>
                  <Play size={20} />
                  Fullscreen control
                </span>
              </div>
            </div>
          </div>
        </section>

        <section className="final-download">
          <div className="page-width final-layout">
            <div>
              <span className="section-label">Start watching</span>
              <h2>Bring the movie. Syncy handles the room.</h2>
            </div>
            <div className="final-actions">
              <a className="button dark" href={release.androidUrl}>
                <Smartphone size={18} />
                Android
              </a>
              <a className="button light" href={release.windowsUrl}>
                <Monitor size={18} />
                Windows
              </a>
            </div>
          </div>
        </section>
      </main>

      <footer>
        <div className="page-width footer-inner">
          <div className="footer-brand">
            <img src="/logo.png" alt="" />
            <div>
              <strong>Syncy</strong>
              <span>Local media. Shared time.</span>
            </div>
          </div>
          <div className="footer-links">
            <a href={release.releaseUrl} target="_blank" rel="noreferrer">
              {release.version}
            </a>
            <a href={repoUrl} target="_blank" rel="noreferrer">
              Source
            </a>
            <a href={`${repoUrl}/issues`} target="_blank" rel="noreferrer">
              Issues
            </a>
          </div>
          <p>Built by Khaled Muhammad / 2026</p>
        </div>
      </footer>
    </div>
  );
}

export default App;
