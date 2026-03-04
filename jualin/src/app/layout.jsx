import { Poppins, JetBrains_Mono } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "../context/AuthProvider";
import AppChrome from "../components/ui/AppChrome.jsx";
import { ChatProvider } from "@/context/ChatProvider";
import { QueryProvider } from "@/context/QueryProvider";
import { Toaster } from "sonner";

const poppins = Poppins({
  variable: "--font-poppins",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800"],
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "swap",
});

export const metadata = {
  title: "Jualin",
  description: "Jualin - Your trusted marketplace",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body
        className={`${poppins.variable} ${jetbrainsMono.variable} antialiased`}
      >
        <QueryProvider>
          <AuthProvider>
            <ChatProvider>
              <AppChrome>{children}</AppChrome>
              <Toaster position="top-center" richColors />
            </ChatProvider>
          </AuthProvider>
        </QueryProvider>
      </body>
    </html>
  );
}
