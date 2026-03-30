const appStoreLink = document.getElementById("app-store-link");

if (appStoreLink) {
  appStoreLink.removeAttribute("href");
  appStoreLink.setAttribute("aria-disabled", "true");
}
