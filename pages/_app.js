/* pages/_app.js */
import "../styles/globals.css";
import Link from "next/link";

function MyApp({ Component, pageProps }) {
  return (
    <div>
      <nav className="border-b p-6">
        <div class="flex-wrap mt-4 content-center text-center items-center">
          <p class="text-4xl font-bold text-center inline-flex">
            {" "}
            <a href="#" class="">
              illoMX
            </a>
          </p>{" "}
          <p class="inline-flex text-xs italic font-sans font-normal tracking-tighter text-gray-300">
            alpha
          </p>
        </div>

        <div className="flex-wrap mt-4 content-center text-center items-center">
          <Link href="/">
            <a className="mr-4 text-green-700 tracking-tight text-semi-bold">
              market
            </a>
          </Link>
          <Link href="/create-item">
            <a className="mr-6 text-green-700 tracking-tight text-semi-bold">
              create NFT
            </a>
          </Link>

          <Link href="/creator-dashboard">
            <a className="mr-6 text-green-700 tracking-tight text-semi-bold">
              dashboard
            </a>
          </Link>
          <Link href="/faq">
            <a className="mr-6 text-green-700 tracking-tight text-semi-bold">
              faq
            </a>
          </Link>
        </div>
      </nav>
      <Component {...pageProps} />
    </div>
  );
}

export default MyApp;
