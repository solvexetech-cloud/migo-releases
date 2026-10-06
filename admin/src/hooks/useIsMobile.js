import { useEffect, useState } from 'react';

/**
 * Returns true if viewport width < breakpoint (default 768px).
 * Auto-updates on window resize.
 */
export function useIsMobile(breakpoint = 768) {
  const [isMobile, setIsMobile] = useState(() => {
    if (typeof window === 'undefined') return false;
    return window.innerWidth < breakpoint;
  });

  useEffect(() => {
    function handle() {
      setIsMobile(window.innerWidth < breakpoint);
    }
    window.addEventListener('resize', handle);
    handle();
    return () => window.removeEventListener('resize', handle);
  }, [breakpoint]);

  return isMobile;
}