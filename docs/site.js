(function () {
  'use strict';

  /* ========================================================================
     1. Two-State Eye-Comfort Theme Toggle (per modern-web-guidance)
        - Stores literal "light" or "dark" only when overriding system preference.
        - Removes stored key when toggling back to match system preference.
     ======================================================================== */
  const colorSchemeMeta = document.querySelector('meta[name="color-scheme"]');
  const themeToggleBtn = document.getElementById('theme-toggle');

  function getSystemScheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function getStoredScheme() {
    try {
      const stored = localStorage.getItem('color-scheme');
      return stored === 'light' || stored === 'dark' ? stored : null;
    } catch (_) {
      return null;
    }
  }

  function applyScheme(value) {
    if (colorSchemeMeta) {
      colorSchemeMeta.content = value || 'light dark';
    }
  }

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', () => {
      const systemScheme = getSystemScheme();
      const currentRendered = getStoredScheme() || systemScheme;
      const targetScheme = currentRendered === 'dark' ? 'light' : 'dark';

      if (targetScheme === systemScheme) {
        try {
          localStorage.removeItem('color-scheme');
        } catch (_) {}
        applyScheme('light dark');
      } else {
        try {
          localStorage.setItem('color-scheme', targetScheme);
        } catch (_) {}
        applyScheme(targetScheme);
      }
    });
  }

  window.addEventListener('storage', (event) => {
    if (event.key === 'color-scheme') {
      applyScheme(event.newValue || 'light dark');
    }
  });

  /* ========================================================================
     2. Hero Screenshot Switcher + Native Light-Dismiss Lightbox (<dialog>)
     ======================================================================== */
  const previewImg = document.getElementById('hero-preview-img');
  const previewCaption = document.getElementById('hero-preview-caption');
  const previewTrigger = document.getElementById('hero-preview-trigger');
  const screenSwitchBtns = document.querySelectorAll('[data-screen-src]');
  const lightbox = document.getElementById('screenshot-lightbox');
  const lightboxImg = document.getElementById('lightbox-img');
  const lightboxTitle = document.getElementById('lightbox-title');

  let activeScreen = {
    src: previewImg ? previewImg.getAttribute('src') : '',
    alt: previewImg ? previewImg.getAttribute('alt') : '',
    title: 'Roof Ledger Home Dashboard',
  };

  screenSwitchBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      screenSwitchBtns.forEach((b) => b.setAttribute('aria-pressed', 'false'));
      btn.setAttribute('aria-pressed', 'true');

      activeScreen = {
        src: btn.dataset.screenSrc || activeScreen.src,
        alt: btn.dataset.screenAlt || activeScreen.alt,
        title: btn.dataset.screenTitle || activeScreen.title,
      };

      if (previewImg) {
        previewImg.src = activeScreen.src;
        previewImg.alt = activeScreen.alt;
      }
      if (previewCaption) {
        previewCaption.textContent = `${activeScreen.title} — tap to inspect full screen`;
      }
    });
  });

  if (previewTrigger && lightbox) {
    previewTrigger.addEventListener('click', () => {
      if (lightboxImg) {
        lightboxImg.src = activeScreen.src;
        lightboxImg.alt = activeScreen.alt;
      }
      if (lightboxTitle) {
        lightboxTitle.textContent = activeScreen.title;
      }
      if (typeof lightbox.showModal === 'function') {
        lightbox.showModal();
      }
    });

    // Mandatory fallback for browsers without <dialog closedby="any"> support (e.g. Safari)
    if (!('closedBy' in HTMLDialogElement.prototype)) {
      lightbox.addEventListener('click', (event) => {
        if (event.target !== lightbox) return;
        const rect = lightbox.getBoundingClientRect();
        const isDialogContent =
          rect.top <= event.clientY &&
          event.clientY <= rect.top + rect.height &&
          rect.left <= event.clientX &&
          event.clientX <= rect.left + rect.width;
        if (isDialogContent) return;
        lightbox.close();
      });
    }
  }

  /* ========================================================================
     3. Accessible Landlord Workflow Tabs (with Left/Right keyboard navigation)
     ======================================================================== */
  const tabList = document.querySelector('[role="tablist"]');
  if (tabList) {
    const tabs = Array.from(tabList.querySelectorAll('[role="tab"]'));

    function activateTab(tab, focusTab) {
      tabs.forEach((t) => {
        const selected = t === tab;
        t.setAttribute('aria-selected', String(selected));
        t.tabIndex = selected ? 0 : -1;
        const panelId = t.getAttribute('aria-controls');
        const panel = panelId ? document.getElementById(panelId) : null;
        if (panel) {
          panel.hidden = !selected;
        }
      });
      if (focusTab) tab.focus();
    }

    tabs.forEach((tab, idx) => {
      tab.addEventListener('click', () => activateTab(tab, false));
      tab.addEventListener('keydown', (event) => {
        if (event.key === 'ArrowRight') {
          event.preventDefault();
          activateTab(tabs[(idx + 1) % tabs.length], true);
        } else if (event.key === 'ArrowLeft') {
          event.preventDefault();
          activateTab(tabs[(idx - 1 + tabs.length) % tabs.length], true);
        } else if (event.key === 'Home') {
          event.preventDefault();
          activateTab(tabs[0], true);
        } else if (event.key === 'End') {
          event.preventDefault();
          activateTab(tabs[tabs.length - 1], true);
        }
      });
    });
  }

  /* ========================================================================
     4. Monthly / Annual Pricing Switcher
     ======================================================================== */
  const billingBtns = document.querySelectorAll('[data-billing]');
  const priceNodes = document.querySelectorAll('[data-price-monthly]');

  billingBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      const mode = btn.dataset.billing === 'annual' ? 'annual' : 'monthly';
      billingBtns.forEach((b) => b.setAttribute('aria-pressed', String(b === btn)));

      priceNodes.forEach((card) => {
        const priceEl = card.querySelector('.plan-price');
        const unitEl = card.querySelector('.plan-unit');
        const noteEl = card.querySelector('.plan-subnote');

        if (mode === 'annual') {
          if (priceEl) priceEl.textContent = card.dataset.priceAnnual || '';
          if (unitEl) unitEl.textContent = '/ year';
          if (noteEl) noteEl.textContent = card.dataset.noteAnnual || '';
        } else {
          if (priceEl) priceEl.textContent = card.dataset.priceMonthly || '';
          if (unitEl) unitEl.textContent = '/ month';
          if (noteEl) noteEl.textContent = card.dataset.noteMonthly || '';
        }
      });
    });
  });

  /* ========================================================================
     5. Dynamic GitHub Releases Latest Version Sync
     ======================================================================== */
  (async function syncLatestRelease() {
    try {
      const res = await fetch('https://api.github.com/repos/Watot12345/Tenera/releases/latest');
      if (!res.ok) return;
      const data = await res.json();
      const tag = data.tag_name;
      if (!tag) return;

      const releaseText = document.getElementById('release-version-text');
      const heroDownloadLabel = document.getElementById('download-cta-label');
      const heroDownloadCta = document.getElementById('download-cta');

      if (releaseText) {
        releaseText.textContent = `Official Release ${tag} · Android 7.0+`;
      }
      if (heroDownloadLabel) {
        heroDownloadLabel.textContent = `Download APK (${tag})`;
      }

      const apkAsset = Array.isArray(data.assets)
        ? data.assets.find((a) => a.name && a.name.endsWith('.apk'))
        : null;

      if (apkAsset && apkAsset.browser_download_url && heroDownloadCta) {
        heroDownloadCta.href = apkAsset.browser_download_url;
      }
    } catch (_) {
      // Keep static fallback links silently
    }
  })();
})();
