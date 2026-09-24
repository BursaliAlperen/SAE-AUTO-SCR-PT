#!/usr/bin/env python3
import os, sys, json, time, random, subprocess, threading, requests, socket, hashlib, base64, string
from datetime import datetime
from colorama import init, Fore, Style
init(autoreset=True)

class SystemInstaller:
    @staticmethod
    def install_packages():
        print(Fore.CYAN + "[1/10] Sistem paketleri kuruluyor...")
        packages = ["python","python-pip","git","nodejs","npm","curl","wget","jq","tor","proxychains-ng","openvpn","stunnel","nmap","netcat-openbsd"]
        for pkg in packages:
            os.system("pkg install -y " + pkg + " 2>/dev/null")
        print(Fore.GREEN + "[+] Paketler kuruldu")
        pip_packages = ["requests","colorama","beautifulsoup4","selenium","webdriver-manager","fake-useragent","pyotp","cryptography","pynacl","stem"]
        for pkg in pip_packages:
            os.system("pip install " + pkg + " 2>/dev/null")
        os.system("npm install -g puppeteer puppeteer-extra puppeteer-extra-plugin-stealth axios 2>/dev/null")
        print(Fore.GREEN + "[+] Python ve Node.js paketleri kuruldu")

    @staticmethod
    def setup_directories():
        dirs = ["config","data","logs","proxies","sessions","vpn"]
        for d in dirs:
            os.makedirs(d, exist_ok=True)
        print(Fore.GREEN + "[+] Dizinler olusturuldu")

class VPNManager:
    def __init__(self):
        self.vpn_configs = []
        self.current_ip = None

    def get_free_vpn_configs(self):
        print(Fore.CYAN + "[2/10] VPN configleri toplaniyor...")
        vpn_sources = ["https://www.vpngate.net/api/iphone/","https://freevpn.me/accounts/","https://www.vpnbook.com/freevpn"]
        for source in vpn_sources:
            try:
                response = requests.get(source, timeout=10)
                if response.status_code == 200:
                    lines = response.text.split('\n')
                    for line in lines:
                        if 'openvpn' in line.lower() or 'ovpn' in line.lower():
                            self.vpn_configs.append(line.strip())
            except:
                continue
        print(Fore.GREEN + "[+] " + str(len(self.vpn_configs)) + " VPN config bulundu")

    def setup_openvpn(self):
        print(Fore.CYAN + "[3/10] OpenVPN kuruluyor...")
        vpn_config = "client\ndev tun\nproto udp\nremote 192.168.1.1 1194\nresolv-retry infinite\nnobind\npersist-key\npersist-tun\nremote-cert-tls server\ncipher AES-256-CBC\nverb 3\n"
        with open("vpn/config.ovpn","w") as f:
            f.write(vpn_config)
        print(Fore.GREEN + "[+] OpenVPN hazir")

    def setup_tor(self):
        print(Fore.CYAN + "[4/10] Tor proxy kuruluyor...")
        tor_config = "SOCKSPort 9050\nControlPort 9051\nCookieAuthentication 1\n"
        with open("config/torrc","w") as f:
            f.write(tor_config)
        os.system("tor -f config/torrc &")
        time.sleep(3)
        print(Fore.GREEN + "[+] Tor proxy aktif")

    def get_public_ip(self):
        try:
            response = requests.get("https://api.ipify.org", timeout=5)
            return response.text
        except:
            return None

    def rotate_ip(self):
        print(Fore.YELLOW + "[*] IP rotasyonu yapiliyor...")
        try:
            with socket.create_connection(("127.0.0.1",9051), timeout=5) as sock:
                sock.send(b"AUTHENTICATE\r\nSIGNAL NEWNYM\r\nQUIT\r\n")
                response = sock.recv(1024)
                if b"250" in response:
                    print(Fore.GREEN + "[+] Tor kimlik degistirildi")
        except:
            pass
        time.sleep(2)
        self.current_ip = self.get_public_ip()
        if self.current_ip:
            print(Fore.GREEN + "[+] Yeni IP: " + self.current_ip)
        else:
            print(Fore.RED + "[-] IP alinamadi")
        return self.current_ip

class ProxyManager:
    def __init__(self):
        self.proxies = []

    def fetch_proxies(self):
        print(Fore.CYAN + "[5/10] Proxy listesi toplaniyor...")
        proxy_sources = [
            "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all",
            "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt",
            "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt",
            "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt"
        ]
        all_proxies = []
        for source in proxy_sources:
            try:
                response = requests.get(source, timeout=10)
                if response.status_code == 200:
                    lines = response.text.strip().split('\n')
                    for line in lines:
                        if ':' in line:
                            all_proxies.append(line.strip())
            except:
                continue
        self.proxies = list(set(all_proxies))
        working_proxies = []
        for proxy in self.proxies[:50]:
            try:
                test = requests.get("http://httpbin.org/ip", proxies={"http":"http://"+proxy,"https":"http://"+proxy}, timeout=5)
                if test.status_code == 200:
                    working_proxies.append(proxy)
            except:
                continue
        self.proxies = working_proxies
        with open("proxies/list.txt","w") as f:
            for proxy in self.proxies:
                f.write(proxy + "\n")
        print(Fore.GREEN + "[+] " + str(len(self.proxies)) + " calisan proxy bulundu")

    def get_random_proxy(self):
        if self.proxies:
            return random.choice(self.proxies)
        return None

class AccountManager:
    def __init__(self):
        self.accounts_file = "data/accounts.json"
        self.accounts = []
        self.load_accounts()

    def load_accounts(self):
        if os.path.exists(self.accounts_file):
            with open(self.accounts_file,'r') as f:
                self.accounts = json.load(f)
        else:
            self.accounts = []

    def save_accounts(self):
        with open(self.accounts_file,'w') as f:
            json.dump(self.accounts, f, indent=2)

    def generate_random_username(self):
        prefixes = ["Player","Gamer","Pro","Master","Shadow","Night","Dark","Cool","Epic","Mega","Super","Ultra","Hyper","Turbo","Alpha","Beta","Delta","Omega","XxX","Wolf","Dragon","Tiger","Falcon","Phoenix","Titan","Legend","Rider","Hunter","Ninja","Samurai"]
        suffixes = ["_YT","_Pro","_Master","_King","_Queen","_Star","_Lord","_Hero","_Champ","_Legend","_God","_Wizard","_Knight","_Demon","_Angel","_Ghost","_Storm","_Blaze","_Frost","_Thunder"]
        numbers = str(random.randint(100,9999))
        return random.choice(prefixes) + random.choice(suffixes) + numbers

    def generate_random_password(self, length=12):
        chars = string.ascii_letters + string.digits + "!@#$%^&*"
        return ''.join(random.choice(chars) for _ in range(length))

    def generate_random_email(self, username):
        domains = ["gmail.com","yahoo.com","hotmail.com","outlook.com","protonmail.com","mail.com"]
        return username.lower() + str(random.randint(1,999)) + "@" + random.choice(domains)

    def generate_random_birthday(self):
        year = random.randint(1970,2005)
        month = random.randint(1,12)
        day = random.randint(1,28)
        return str(year) + "-" + str(month) + "-" + str(day)

    def generate_random_gender(self):
        return random.choice([0,1,2])

    def generate_account(self):
        username = self.generate_random_username()
        password = self.generate_random_password()
        email = self.generate_random_email(username)
        birthday = self.generate_random_birthday()
        gender = self.generate_random_gender()
        account = {
            "username": username,
            "password": password,
            "email": email,
            "birthday": birthday,
            "gender": gender,
            "cookie": None,
            "added_date": datetime.now().isoformat(),
            "last_login": None,
            "login_count": 0,
            "status": "active",
            "is_banned": False
        }
        self.accounts.append(account)
        self.save_accounts()
        print(Fore.GREEN + "[+] Otomatik hesap olusturuldu: " + username + " / " + password)
        return account

    def generate_accounts(self, count):
        for i in range(count):
            self.generate_account()

    def add_account(self, username, password, cookie=None):
        account = {
            "username": username,
            "password": password,
            "cookie": cookie,
            "added_date": datetime.now().isoformat(),
            "last_login": None,
            "login_count": 0,
            "status": "active",
            "is_banned": False
        }
        self.accounts.append(account)
        self.save_accounts()
        print(Fore.GREEN + "[+] " + username + " hesabi eklendi")

    def remove_account(self, username):
        self.accounts = [acc for acc in self.accounts if acc['username'] != username]
        self.save_accounts()
        print(Fore.GREEN + "[+] " + username + " silindi")

    def list_accounts(self):
        print("\n" + "="*50)
        print(Fore.CYAN + "KAYITLI HESAPLAR")
        print("="*50)
        for i, acc in enumerate(self.accounts, 1):
            status = Fore.GREEN + "AKTIF" if acc['status'] == "active" else Fore.RED + "PASIF"
            print(str(i) + ". " + acc['username'] + " - " + status + " - " + str(acc['login_count']) + " giris")
        print("="*50)

class RobloxBot:
    def __init__(self, vpn_manager, proxy_manager):
        self.vpn = vpn_manager
        self.proxy_manager = proxy_manager
        self.session = None
        self.game_id = None

    def create_session(self):
        session = requests.Session()
        proxy = self.proxy_manager.get_random_proxy()
        if proxy:
            session.proxies = {'http':'http://'+proxy,'https':'http://'+proxy}
        user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
        ]
        session.headers.update({
            'User-Agent': random.choice(user_agents),
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'tr-TR,tr;q=0.9,en;q=0.8',
            'Origin': 'https://www.roblox.com',
            'Referer': 'https://www.roblox.com/'
        })
        return session

    def get_csrf_token(self, session):
        try:
            response = session.post('https://auth.roblox.com/v2/logout')
            if 'x-csrf-token' in response.headers:
                return response.headers['x-csrf-token']
        except:
            pass
        return None

    def login_with_cookie(self, cookie):
        session = self.create_session()
        session.cookies.set('.ROBLOSECURITY', cookie, domain='.roblox.com')
        try:
            response = session.get('https://www.roblox.com/mobileapi/userinfo')
            if response.status_code == 200:
                user_info = response.json()
                return session, user_info
        except:
            pass
        return None, None

    def login_with_password(self, username, password):
        session = self.create_session()
        csrf = self.get_csrf_token(session)
        if csrf:
            session.headers['X-CSRF-TOKEN'] = csrf
        login_data = {
            "username": username,
            "password": password,
            "securityQuestionID": "",
            "securityQuestionAnswer": "",
            "cvalue": False
        }
        try:
            response = session.post('https://auth.roblox.com/v2/login', json=login_data)
            if response.status_code == 200:
                return session, response.json()
        except:
            pass
        return None, None

    def join_game(self, session, game_id):
        try:
            game_url = "https://www.roblox.com/games/" + game_id
            response = session.get(game_url)
            if response.status_code == 200:
                join_url = "https://gamejoin.roblox.com/v1/join/" + game_id
                join_response = session.post(join_url)
                if join_response.status_code == 200:
                    print(Fore.GREEN + "[+] Oyuna katilim basarili: " + game_id)
                    return True
        except:
            pass
        return False

    def leave_game(self, session, game_id):
        try:
            leave_url = "https://gamejoin.roblox.com/v1/leave/" + game_id
            response = session.post(leave_url)
            if response.status_code == 200:
                print(Fore.GREEN + "[+] Oyundan cikis basarili: " + game_id)
                return True
        except:
            pass
        return False

    def process_account(self, account):
        session = None
        user_info = None
        if account.get('cookie'):
            session, user_info = self.login_with_cookie(account['cookie'])
        if not session:
            session, user_info = self.login_with_password(account['username'], account['password'])
        if session and user_info:
            print(Fore.CYAN + "[+] " + account['username'] + " giris basarili")
            if self.game_id:
                if self.join_game(session, self.game_id):
                    stay_time = random.uniform(30, 90)
                    print(Fore.YELLOW + "[*] Oyunda " + str(int(stay_time)) + " saniye kaliniyor...")
                    time.sleep(stay_time)
                    self.leave_game(session, self.game_id)
                    account['last_login'] = datetime.now().isoformat()
                    account['login_count'] += 1
                    return True
        print(Fore.RED + "[-] " + account['username'] + " islem basarisiz")
        return False

    def run_rotation(self, accounts, interval_minutes=15):
        print(Fore.MAGENTA + "[*] " + str(len(accounts)) + " hesap ile rotasyon baslatildi")
        print(Fore.CYAN + "[*] Oyun ID: " + self.game_id)
        print(Fore.CYAN + "[*] Rotasyon araligi: " + str(interval_minutes) + " dakika")
        while True:
            for account in accounts:
                if account['status'] == 'active' and not account.get('is_banned', False):
                    print(Fore.YELLOW + "[*] " + account['username'] + " isleniyor...")
                    self.vpn.rotate_ip()
                    self.process_account(account)
                    delay = random.uniform(30, 90)
                    print(Fore.CYAN + "[*] " + str(int(delay)) + " saniye bekleniyor...")
                    time.sleep(delay)
            print(Fore.GREEN + "[*] " + str(interval_minutes) + " dakika bekleniyor, sonra tekrar basliyor...")
            time.sleep(interval_minutes * 60)

class MenuSystem:
    def __init__(self):
        self.installer = SystemInstaller()
        self.vpn = VPNManager()
        self.proxy = ProxyManager()
        self.accounts = AccountManager()
        self.bot = RobloxBot(self.vpn, self.proxy)

    def setup_all(self):
        print(Fore.YELLOW + "\n" + "="*50)
        print(Fore.CYAN + "ROBLOX MEGA BOT - KURULUM BASLADI")
        print(Fore.YELLOW + "="*50)
        self.installer.install_packages()
        self.installer.setup_directories()
        self.vpn.get_free_vpn_configs()
        self.vpn.setup_openvpn()
        self.vpn.setup_tor()
        self.proxy.fetch_proxies()
        self.vpn.rotate_ip()
        print(Fore.GREEN + "\n[+] Tum sistem kurulumu tamamlandi")
        print(Fore.YELLOW + "="*50)

    def show_menu(self):
        print("\n" + "="*50)
        print(Fore.CYAN + "ROBLOX MEGA BOT - ANA MENU")
        print("="*50)
        print("1. Sistemi Kur (VPN + Proxy)")
        print("2. Otomatik Hesap Olustur")
        print("3. Manuel Hesap Ekle")
        print("4. Hesaplari Listele")
        print("5. Hesap Sil")
        print("6. Botu Baslat (Oto Gir-Cik)")
        print("7. IP Degistir")
        print("8. Proxy Guncelle")
        print("9. Cikis")
        print("="*50)

    def run(self):
        while True:
            self.show_menu()
            choice = input("Seciminiz: ")
            if choice == '1':
                self.setup_all()
            elif choice == '2':
                count = input("Kac hesap olusturulsun? [5]: ")
                count = int(count) if count else 5
                self.accounts.generate_accounts(count)
            elif choice == '3':
                print("\n--- Manuel Hesap Ekleme ---")
                print("1. Sifre ile ekle")
                print("2. Cookie ile ekle")
                add_choice = input("Secim: ")
                if add_choice == '1':
                    username = input("Kullanici adi: ")
                    password = input("Sifre: ")
                    self.accounts.add_account(username, password)
                elif add_choice == '2':
                    username = input("Kullanici adi: ")
                    cookie = input("Cookie: ")
                    self.accounts.add_account(username, "", cookie)
            elif choice == '4':
                self.accounts.list_accounts()
            elif choice == '5':
                username = input("Silinecek kullanici adi: ")
                self.accounts.remove_account(username)
            elif choice == '6':
                if not self.accounts.accounts:
                    print(Fore.RED + "[-] Once hesap ekleyin veya otomatik olusturun")
                    continue
                game_id = input("Oyun ID (ornek: 97224366404867): ")
                self.bot.game_id = game_id
                interval = input("Rotasyon araligi (dakika) [15]: ")
                interval = int(interval) if interval else 15
                print(Fore.GREEN + "[+] Bot baslatiliyor...")
                self.bot.run_rotation(self.accounts.accounts, interval)
            elif choice == '7':
                self.vpn.rotate_ip()
            elif choice == '8':
                self.proxy.fetch_proxies()
            elif choice == '9':
                print(Fore.YELLOW + "Cikis yapiliyor...")
                break
            else:
                print(Fore.RED + "Gecersiz secim")

if __name__ == "__main__":
    print(Fore.CYAN + """
    ██████╗  ██████╗ ██████╗ ██╗      ██████╗ ██╗  ██╗
    ██╔══██╗██╔═══██╗██╔══██╗██║     ██╔═══██╗╚██╗██╔╝
    ██████╔╝██║   ██║██████╔╝██║     ██║   ██║ ╚███╔╝ 
    ██╔══██╗██║   ██║██╔══██╗██║     ██║   ██║ ██╔██╗ 
    ██║  ██║╚██████╔╝██████╔╝███████╗╚██████╔╝██╔╝ ██╗
    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝
    """)
    print(Fore.YELLOW + "="*50)
    print(Fore.GREEN + "ROBLOX MEGA BOT - Otomatik Hesap + Oto Gir-Cik Sistemi")
    print(Fore.YELLOW + "="*50)
    menu = MenuSystem()
    menu.run()
