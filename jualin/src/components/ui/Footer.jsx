'use client';
import React from 'react';
import Logo from './Logo.jsx';

const Footer = () => {
  return (
    <footer className="bg-[#1f1f1f] text-white pt-12 pb-10 animate-fade-in">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
          <div>
            <div className="flex items-center gap-3">
              <Logo size="xl" />
            </div>
            <p className="mt-4 leading-relaxed text-sm md:text-base text-white/80">
              Marketplace untuk semua kebutuhan Anda. Temukan produk terbaik dari penjual terpercaya dengan pengalaman belanja yang aman, cepat, dan nyaman. Jualin memudahkan Anda menemukan berbagai pilihan barang berkualitas—dari lokal hingga internasional—dalam satu platform yang praktis dan tepercaya.
            </p>
            <div className="mt-6">
              <div className="text-sm font-semibold">Ikuti Kami</div>
              <div className="mt-3 flex items-center gap-3">
                <a aria-label="Facebook" href="#" className="transition-opacity duration-200 hover:opacity-80">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M22 12a10 10 0 1 0-11.6 9.9v-7h-2.4V12h2.4V9.7c0-2.4 1.4-3.8 3.6-3.8 1 0 2 .2 2 .2v2.2h-1.1c-1.1 0-1.5.7-1.5 1.4V12h2.6l-.4 2.9h-2.2v7A10 10 0 0 0 22 12Z"/></svg>
                </a>
                <a aria-label="Instagram" href="#" className="transition-opacity duration-200 hover:opacity-80">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M7 2h10a5 5 0 0 1 5 5v10a5 5 0 0 1-5 5H7a5 5 0 0 1-5-5V7a5 5 0 0 1 5-5Zm10 2H7a3 3 0 0 0-3 3v10a3 3 0 0 0 3 3h10a3 3 0 0 0 3-3V7a3 3 0 0 0-3-3Zm-5 3a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm0 2a3 3 0 1 0 0 6 3 3 0 0 0 0-6Zm5.5-2a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3Z"/></svg>
                </a>
                <a aria-label="X" href="#" className="transition-opacity duration-200 hover:opacity-80">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M3 3h4.7l4.2 6.1L16.9 3H21l-7.4 9.9L21 21h-4.8l-4.6-6.7L7.1 21H3l7.7-10.2L3 3Z"/></svg>
                </a>
                <a aria-label="YouTube" href="#" className="transition-opacity duration-200 hover:opacity-80">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M23.5 6.2a3 3 0 0 0-2.1-2.1C19.3 3.5 12 3.5 12 3.5s-7.3 0-9.4.6A3 3 0 0 0 .5 6.2 31 31 0 0 0 0 12a31 31 0 0 0 .5 5.8 3 3 0 0 0 2.1 2.1c2.1.6 9.4.6 9.4.6s7.3 0 9.4-.6a3 3 0 0 0 2.1-2.1A31 31 0 0 0 24 12a31 31 0 0 0-.5-5.8ZM9.7 15.6V8.4l6.2 3.6-6.2 3.6Z"/></svg>
                </a>
              </div>
            </div>
          </div>

          

          <div>
            <div className="w-full overflow-hidden rounded-lg border border-white/10">
              <iframe
                src="https://www.google.com/maps?q=Kost%20Paviliun%2018%2C%20Jalan%20Ciganitri%20Cijeungjing%20No.18%2C%20Cipagalo%2C%20(sebelah%20cucian%20mobil%20gerald)%2C%20Kab.%20Bandung%2C%20Kec.%20Bojongsoang%2C%20Jawa%20Barat%2C%2040288&output=embed"
                width="100%"
                height="220"
                style={{ border: 0 }}
                loading="lazy"
                allowFullScreen
                aria-label="Lokasi Jualin di Google Maps"
                referrerPolicy="no-referrer-when-downgrade"
              />
            </div>
            <div className="text-sm font-semibold mt-5">Alamat & Kontak</div>
            <div className="mt-4 space-y-3 text-white/80 text-sm">
              <div className="flex items-start gap-3">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2a7 7 0 0 0-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 0 0-7-7Zm0 9.5a2.5 2.5 0 1 1 0-5 2.5 2.5 0 0 1 0 5Z"/></svg>
                <div>
                  Kost Paviliun 18, Jalan Ciganitri Cijeungjing No.18, Cipagalo, (sebelah cucian mobil gerald), Kab. Bandung, Kec. Bojongsoang, Jawa Barat, 40288.
                </div>
              </div>
              <div className="flex items-center gap-3">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M6.6 10.8c1.4 2.8 3.6 5 6.4 6.4l2.1-2.1a1 1 0 0 1 1-.2c1.1.4 2.3.6 3.5.6a1 1 0 0 1 1 1V20a1 1 0 0 1-1 1c-9.4 0-17-7.6-17-17A1 1 0 0 1 3 3h3.5a1 1 0 0 1 1 1c0 1.2.2 2.4.6 3.5a1 1 0 0 1-.2 1l-2.3 2.3Z"/></svg>
                <div>+62 882 002 365 399</div>
              </div>
              <div className="flex items-center gap-3">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M2 6a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6Zm3.2 0 6.8 5.1L18.8 6H5.2ZM20 8.3l-8 6-8-6V18h16V8.3Z"/></svg>
                <div>jualin@jualin.id</div>
              </div>
              <div className="flex items-center gap-3">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm-7-1a1 1 0 0 1-1-1V3h2v2a1 1 0 0 1-1 1Zm14 0a1 1 0 0 1-1-1V3h2v2a1 1 0 0 1-1 1ZM3 20v-2h2v2H3Zm16 0v-2h2v2h-2Z"/></svg>
                <div>Senin–Jumat 09:00–18:00 WIB</div>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-10 border-t border-white/10 pt-6 flex items-center justify-center text-xs sm:text-sm">
          <div className="text-white/70">© {new Date().getFullYear()} Jualin</div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
