import { NextResponse } from 'next/server'

const validRoutes = [
  '/',
  '/dashboard',
  '/product',
  '/profile',
  '/profile/edit',
  '/auth/login',
  '/auth/register',
  '/auth/forgot-password',
  '/auth/reset-password',
  '/chat',
  '/404_not_found',
]

const allowedRoutesWithParams = ['/profile/edit', '/product', '/seller', '/backoffice']

function isValidRoute(pathname) {
  const pathWithoutQuery = pathname.split('?')[0]

  if (validRoutes.includes(pathWithoutQuery)) {
    return true
  }

  for (const route of allowedRoutesWithParams) {
    if (pathWithoutQuery.startsWith(route)) {
      return true
    }
  }

  return false
}

export function middleware(request) {
  const { pathname } = request.nextUrl
  const role = (request.cookies.get('role')?.value || '').toLowerCase()

  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.startsWith('/static') ||
    /\.(ico|png|jpg|jpeg|gif|svg|css|js|json|woff|woff2|ttf|eot)$/.test(pathname)
  ) {
    return NextResponse.next()
  }

  if (pathname.startsWith('/dashboard') && role === 'seller') {
    const url = request.nextUrl.clone()
    url.pathname = '/seller/dashboard'
    return NextResponse.redirect(url)
  }

  if (pathname.startsWith('/seller') && role !== 'seller' && role !== 'admin') {
    const url = request.nextUrl.clone()
    url.pathname = '/dashboard'
    return NextResponse.redirect(url)
  }

  // Admin Role-Based Access Control
  if (pathname.startsWith('/dashboard') && role === 'admin') {
    const url = request.nextUrl.clone()
    url.pathname = '/backoffice'
    return NextResponse.redirect(url)
  }

  if (pathname.startsWith('/backoffice') && role !== 'admin') {
    const url = request.nextUrl.clone()
    url.pathname = '/dashboard'
    return NextResponse.redirect(url)
  }

  if (!isValidRoute(pathname)) {
    const url = request.nextUrl.clone()
    url.pathname = '/404_not_found'
    return NextResponse.redirect(url)
  }

  return NextResponse.next()
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
}
