/* pages/_app.js */
import "../styles/globals.css";
import Link from "next/link";

function MyApp({ Component, pageProps }) {
  return (
    <div>
      <nav className="border-b p-6">
        <p className="text-4xl font-bold text-center">illoMX</p>
        <div className="flex-wrap mt-4 content-center text-center items-center">
          <Link href="/">
            <a className="mr-4 text-green-600">market</a>
          </Link>
          <Link href="/create-item">
            <a className="mr-6 text-green-600">create NFT</a>
          </Link>
          <Link href="/creator-dashboard">
            <a className="mr-6 text-green-600">dashboard</a>
          </Link>
          <Link href="/faq">
            <a className="mr-6 text-green-600">faq</a>
          </Link>
        </div>
      </nav>
      <Component {...pageProps} />
    </div>
  );
}

export default MyApp;
