import { useEffect, useState } from 'react';
import {
  ArrowRight,
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
    title: 'Playback that stays together',
    text: 'Play, pause, and seek are revisioned through one authoritative room state, with reconnect recovery and Android lifecycle protection.',
    accent: 'violet',
  },
  {
    icon: Wifi,
    title: 'Stream from your PC',
    text: 'Pair Android with a Windows PC on your local network, browse its library, and stream the original file with range seeking.',
    accent: 'blue',
  },
  {
    icon: FolderOpen,
    title: 'A real desktop library',
    text: 'Choose folders on Windows, index nested libraries, generate thumbnails, and play formats through the desktop media engine.',
    accent: 'magenta',
  },
  {
    icon: MessageCircle,
    title: 'Conversation in the room',
    text: 'Live chat, typing presence, participant status, and reconnect-safe message history stay beside the video.',
    accent: 'blue',
  },
  {
    icon: Heart,
    title: 'Reactions on the moment',
    text: 'Send lightweight reactions that appear over the player without interrupting playback or taking over the screen.',
    accent: 'magenta',
  },
  {
    icon: Subtitles,
    title: 'Your subtitles, your timing',
    text: 'Load SRT or VTT files, clear them instantly, and adjust subtitle delay when a source track needs correction.',
    accent: 'violet',
  },
  {
    icon: Search,
    title: 'Find the file quickly',
    text: 'Android media discovery, thumbnails, folder browsing, and search make large local collections manageable.',
    accent: 'magenta',
  },
  {
    icon: Gauge,
    title: 'Controls for how you watch',
    text: 'Fullscreen playback, double-tap seeking, desktop keyboard controls, and playback speed from 0.25x to 10x.',
    accent: 'blue',
  },
  {
    icon: ShieldCheck,
    title: 'Guest-first by design',
    text: 'Create or join a room with a display name. Your media remains on your devices or your private local network.',
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

  const closeMenu = () => setMenuOpen(false);

  return (
    <div className="site-shell">
      <header className="site-header">
        <a className="brand" href="#top" aria-label="Syncy home">
          <img src="/logo.png" alt="" />
          <span>Syncy</span>
        </a>

        <nav className={menuOpen ? 'nav-links is-open' : 'nav-links'}>
          <a href="#features" onClick={closeMenu}>
            Features
          </a>
          <a href="#lan" onClick={closeMenu}>
            PC streaming
          </a>
          <a href="#downloads" onClick={closeMenu}>
            Downloads
          </a>
          <a href={repoUrl} target="_blank" rel="noreferrer">
            GitHub
          </a>
        </nav>

        <a className="header-download" href="#downloads">
          <Download size={17} />
          Download
        </a>

        <button
          className="menu-button"
          type="button"
          aria-label={menuOpen ? 'Close navigation' : 'Open navigation'}
          aria-expanded={menuOpen}
          onClick={() => setMenuOpen((open) => !open)}
        >
          {menuOpen ? <X /> : <Menu />}
        </button>
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
          <div className="hero-content">
            <div className="release-kicker">
              <span className="live-dot" />
              {release.version} available now
            </div>
            <h1>Syncy</h1>
            <p className="hero-lead">
              Watch your own videos together. Precise room playback, live chat,
              reactions, subtitles, and direct PC-to-phone streaming.
            </p>
            <div className="hero-actions">
              <a className="button primary" href="#downloads">
                Get the latest build
                <ArrowRight size={19} />
              </a>
              <a
                className="button secondary"
                href={repoUrl}
                target="_blank"
                rel="noreferrer"
              >
                <Github size={19} />
                View source
              </a>
            </div>
          </div>
          <a className="hero-next" href="#downloads" aria-label="View downloads">
            Android + Windows
            <Download size={16} />
          </a>
        </section>

        <section className="download-band" id="downloads">
          <div className="band-intro">
            <span className="section-index">01 / DOWNLOAD</span>
            <h2>Latest release, direct from GitHub.</h2>
            <p>
              {release.version} · {formatDate(release.publishedAt)}
            </p>
          </div>

          <div className="download-options">
            <a
              className="download-row"
              href={release.androidUrl}
              target="_blank"
              rel="noreferrer"
            >
              <span className="platform-icon android">
                <Smartphone />
              </span>
              <span>
                <strong>Android</strong>
                <small>Universal APK · Android 5.0+</small>
              </span>
              <Download size={21} />
            </a>
            <a
              className="download-row"
              href={release.windowsUrl}
              target="_blank"
              rel="noreferrer"
            >
              <span className="platform-icon windows">
                <Monitor />
              </span>
              <span>
                <strong>Windows</strong>
                <small>64-bit portable ZIP</small>
              </span>
              <Download size={21} />
            </a>
          </div>
        </section>

        <section className="feature-section" id="features">
          <div className="section-heading">
            <span className="section-index">02 / WHAT SHIPS</span>
            <h2>More than synchronized play buttons.</h2>
            <p>
              Syncy is a complete watch room for local files, built for phones
              and desktops that need to stay in the same moment.
            </p>
          </div>

          <div className="feature-grid">
            {features.map(({ icon: Icon, title, text, accent }, index) => (
              <article className={`feature-item accent-${accent}`} key={title}>
                <div className="feature-number">
                  {String(index + 1).padStart(2, '0')}
                </div>
                <Icon size={25} strokeWidth={1.8} />
                <h3>{title}</h3>
                <p>{text}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="lan-section" id="lan">
          <div className="lan-copy">
            <span className="section-index">03 / PC TO PHONE</span>
            <h2>Your Windows library, available on the couch.</h2>
            <p>
              Pair once over your private LAN. Syncy discovers the PC, opens its
              indexed folders on Android, and streams the selected source file
              without uploading it to a cloud library.
            </p>
            <ul>
              <li>
                <Check size={18} /> Six-digit pairing and saved trusted devices
              </li>
              <li>
                <Check size={18} /> Nested folder browsing and video thumbnails
              </li>
              <li>
                <Check size={18} /> HTTP range support for responsive seeking
              </li>
            </ul>
          </div>

          <div className="connection-map" aria-label="Windows to Android flow">
            <div className="device-node">
              <Monitor />
              <strong>Windows PC</strong>
              <span>Indexes and serves</span>
            </div>
            <div className="connection-line">
              <span />
              <div>
                <Wifi size={20} />
                PRIVATE LAN
              </div>
            </div>
            <div className="device-node">
              <Smartphone />
              <strong>Android</strong>
              <span>Browses and plays</span>
            </div>
          </div>
        </section>

        <section className="reliability-section">
          <div className="reliability-visual">
            <div className="state-line">
              <span>ROOM REVISION 184</span>
              <strong>PAUSED · 01:22:16</strong>
            </div>
            <div className="sync-track">
              <span className="track-fill" />
              <span className="track-marker marker-one" />
              <span className="track-marker marker-two" />
              <span className="track-marker marker-three" />
            </div>
            <div className="peer-grid">
              <span><Monitor size={18} /> HOST · SYNCED</span>
              <span><Smartphone size={18} /> ANDROID · SYNCED</span>
              <span><RefreshCw size={18} /> RECONNECT · RESTORED</span>
            </div>
          </div>
          <div className="reliability-copy">
            <span className="section-index">04 / RELIABLE STATE</span>
            <h2>The newest command wins. Every time.</h2>
            <p>
              Playback state is revisioned on the backend and applied in order
              on every client. Reconnects, split screen, and Android system UI
              transitions reconcile against the room instead of guessing.
            </p>
            <div className="reliability-points">
              <span><Zap size={18} /> Millisecond positions</span>
              <span><RefreshCw size={18} /> Resume refresh</span>
              <span><ShieldCheck size={18} /> Stale command rejection</span>
            </div>
          </div>
        </section>

        <section className="room-section">
          <div className="section-heading compact">
            <span className="section-index">05 / IN THE ROOM</span>
            <h2>Keep the movie central. Keep everyone present.</h2>
          </div>
          <div className="room-layout">
            <div className="room-player">
              <img src="/hero_ui.jpg" alt="Syncy media library on Android" />
              <div className="play-control"><Play fill="currentColor" /></div>
            </div>
            <div className="room-notes">
              <div>
                <MessageCircle />
                <h3>Live chat</h3>
                <p>History, typing indicators, and online presence.</p>
              </div>
              <div>
                <Heart />
                <h3>Floating reactions</h3>
                <p>Quick reactions land over the moment and clear naturally.</p>
              </div>
              <div>
                <Subtitles />
                <h3>Subtitle control</h3>
                <p>SRT, VTT, and timing offsets without changing the source.</p>
              </div>
            </div>
          </div>
        </section>

        <section className="final-download">
          <div>
            <span className="section-index">READY WHEN YOU ARE</span>
            <h2>Start the room. Bring your own movie.</h2>
          </div>
          <div className="final-actions">
            <a className="button primary" href={release.androidUrl}>
              <Smartphone size={19} />
              Android
            </a>
            <a className="button light" href={release.windowsUrl}>
              <Monitor size={19} />
              Windows
            </a>
          </div>
        </section>
      </main>

      <footer>
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
        <p>Built by Khaled Muhammad · 2026</p>
      </footer>
    </div>
  );
}

export default App;
