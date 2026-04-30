import os

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service


def before_all(context):
    base_url = os.environ.get("BASE_URL", "http://127.0.0.1:5000/gui")
    context.base_url = base_url.rstrip("/")

    options = Options()
    # headless by default (can be overridden by HEADLESS=0)
    headless_env = os.environ.get("HEADLESS", "1").strip().lower()
    headless = headless_env not in ("0", "false", "no", "off")
    if headless:
        # For modern Chrome versions; if your image has an older Chrome, switch to "--headless"
        options.add_argument("--headless=new")

    chrome_bin = os.environ.get("CHROME_BIN", "/usr/bin/chromium")
    if os.path.exists(chrome_bin):
        options.binary_location = chrome_bin

    options.add_argument("--window-size=1400,900")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    chromedriver_bin = os.environ.get("CHROMEDRIVER_BIN", "/usr/bin/chromedriver")
    service = Service(executable_path=chromedriver_bin) if os.path.exists(chromedriver_bin) else Service()
    context.driver = webdriver.Chrome(service=service, options=options)
    context.driver.implicitly_wait(5)


def after_all(context):
    if hasattr(context, "driver") and context.driver:
        context.driver.quit()
