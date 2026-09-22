--[[
    ═══════════════════════════════════════════════════════════════════════
    ScriptVault — Steal an Egg · AAA AutoFarm v6.0 (COMPLETE)
    ═══════════════════════════════════════════════════════════════════════
    • Every function defined · every handler bound · nothing missing
    • Boot: red test frame → 3-tier parent fallback → AAA UI
    • 6 languages · autofarm · ESP · anti-cheat · notifications
    • Loadstring-safe: loadstring(game:HttpGet("..."))()
    ═══════════════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════════
-- BOOT LOG
-- ═══════════════════════════════════════════════════════════════
local function LOG(...)
    pcall(function() print("[SV-BOOT]", ...) end)
end
LOG("═══════════════════════════════════════")
LOG("SV v6.0 starting")

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players, UIS, TS, RunService, WS, SoundService, HttpService, RS
local VirtualUser, CoreGuiService, StatsSvc

pcall(function() Players = game:GetService("Players") end)
pcall(function() UIS = game:GetService("UserInputService") end)
pcall(function() TS = game:GetService("TweenService") end)
pcall(function() RunService = game:GetService("RunService") end)
pcall(function() WS = game:GetService("Workspace") end)
pcall(function() SoundService = game:GetService("SoundService") end)
pcall(function() HttpService = game:GetService("HttpService") end)
pcall(function() RS = game:GetService("ReplicatedStorage") end)
pcall(function() VirtualUser = game:GetService("VirtualUser") end)
pcall(function() CoreGuiService = game:GetService("CoreGui") end)
pcall(function() StatsSvc = game:GetService("Stats") end)

if not Players or not UIS or not TS or not WS or not RS then
    LOG("FATAL: Required Roblox services are unavailable")
    return
end
local LP = Players.LocalPlayer
if not LP then LOG("FATAL: LocalPlayer missing"); return end

-- Each injection gets its own runtime id. Older injections stop their loops
-- after a newer copy replaces this value in the shared executor environment.
local GLOBAL_ENV = (type(getgenv) == "function" and getgenv()) or _G
local SV_RUNTIME_ID = tostring({})
if GLOBAL_ENV then
    GLOBAL_ENV.SV_RUNTIME_ID = SV_RUNTIME_ID
end
local function isCurrentRuntime()
    return not GLOBAL_ENV or GLOBAL_ENV.SV_RUNTIME_ID == SV_RUNTIME_ID
end
LOG("Player:", LP.Name)

local IS_TOUCH = UIS and UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ═══════════════════════════════════════════════════════════════
-- GUI PARENT — validated with write test
-- ═══════════════════════════════════════════════════════════════
local function testParent(inst)
    if not inst then return false end
    local test = Instance.new("Folder")
    test.Name = "SV_TEST_PARENT"
    local ok = pcall(function() test.Parent = inst end)
    local passed = ok and test.Parent == inst
    pcall(function() test:Destroy() end)
    return passed
end

local GUI_PARENT, GUI_PARENT_NAME

pcall(function()
    if gethui then
        local h = gethui()
        if h and testParent(h) then
            GUI_PARENT = h
            GUI_PARENT_NAME = "gethui"
        end
    end
end)
LOG("gethui:", GUI_PARENT_NAME or "FAIL")

if not GUI_PARENT then
    pcall(function()
        if CoreGuiService and testParent(CoreGuiService) then
            GUI_PARENT = CoreGuiService
            GUI_PARENT_NAME = "CoreGui"
        end
    end)
end
LOG("CoreGui:", GUI_PARENT_NAME or "FAIL")

if not GUI_PARENT then
    pcall(function()
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        if not pg then pg = LP:WaitForChild("PlayerGui", 5) end
        if pg and testParent(pg) then
            GUI_PARENT = pg
            GUI_PARENT_NAME = "PlayerGui"
        end
    end)
end
LOG("PlayerGui:", GUI_PARENT_NAME or "FAIL")

if not GUI_PARENT then
    LOG("═══════════════════════════════════════")
    LOG("FATAL: No valid GUI parent.")
    LOG("Your executor blocks ALL. Try Delta/Arceus X.")
    LOG("═══════════════════════════════════════")
    return
end

LOG(">>> Working parent:", GUI_PARENT_NAME)

-- Clean old
local OLD = GUI_PARENT:FindFirstChild("ScriptVault_Egg_AAA")
if OLD then pcall(function() OLD:Destroy() end) end

-- Create ScreenGui
local SCREEN
pcall(function()
    SCREEN = Instance.new("ScreenGui")
    SCREEN.Name = "ScriptVault_Egg_AAA"
    SCREEN.ResetOnSpawn = false
    SCREEN.IgnoreGuiInset = true
    SCREEN.DisplayOrder = 9999
    SCREEN.Parent = GUI_PARENT
end)
if not SCREEN or SCREEN.Parent ~= GUI_PARENT then
    LOG("FATAL: ScreenGui creation failed")
    return
end
LOG("ScreenGui OK")

-- ═══════════════════════════════════════════════════════════════
-- RED TEST FRAME
-- ═══════════════════════════════════════════════════════════════
pcall(function()
    local test = Instance.new("Frame")
    test.Name = "SV_REDTEST"
    test.Size = UDim2.new(0, 240, 0, 120)
    test.Position = UDim2.new(0.5, -120, 0.5, -60)
    test.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
    test.BorderSizePixel = 4
    test.BorderColor3 = Color3.fromRGB(255, 255, 255)
    test.ZIndex = 500000
    test.Parent = SCREEN

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "SV WORKING ✓"
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextSize = 24
    lbl.Font = Enum.Font.GothamBold
    lbl.ZIndex = 500001
    lbl.Parent = test

    task.delay(2, function()
        pcall(function()
            test.Visible = false
            task.wait(0.1)
            test:Destroy()
        end)
    end)
end)
LOG("RED TEST drawn")

-- ═══════════════════════════════════════════════════════════════
-- COLORS
-- ═══════════════════════════════════════════════════════════════
local C = {
    primary   = Color3.fromRGB(37, 99, 235),
    primary_d = Color3.fromRGB(29, 78, 216),
    primary_l = Color3.fromRGB(96, 165, 250),
    primary_xl= Color3.fromRGB(191, 219, 254),
    accent    = Color3.fromRGB(14, 165, 233),
    accent_l  = Color3.fromRGB(125, 211, 252),
    violet    = Color3.fromRGB(139, 92, 246),
    indigo    = Color3.fromRGB(99, 102, 241),
    bg        = Color3.fromRGB(248, 250, 252),
    bg_deep   = Color3.fromRGB(241, 245, 249),
    card      = Color3.fromRGB(255, 255, 255),
    card_alt  = Color3.fromRGB(241, 245, 249),
    hover     = Color3.fromRGB(239, 246, 255),
    sky       = Color3.fromRGB(224, 242, 254),
    text      = Color3.fromRGB(15, 23, 42),
    text_soft = Color3.fromRGB(51, 65, 85),
    text_mut  = Color3.fromRGB(100, 116, 139),
    text_dim  = Color3.fromRGB(148, 163, 184),
    success   = Color3.fromRGB(16, 185, 129),
    success_l = Color3.fromRGB(209, 250, 229),
    success_d = Color3.fromRGB(5, 150, 105),
    danger    = Color3.fromRGB(239, 68, 68),
    danger_l  = Color3.fromRGB(254, 226, 226),
    warn      = Color3.fromRGB(245, 158, 11),
    warn_l    = Color3.fromRGB(254, 243, 199),
    gold      = Color3.fromRGB(250, 204, 21),
    border    = Color3.fromRGB(226, 232, 240),
    border_h  = Color3.fromRGB(203, 213, 225),
    shadow    = Color3.fromRGB(15, 23, 42),
    white     = Color3.fromRGB(255, 255, 255),
}

-- ═══════════════════════════════════════════════════════════════
-- LANGUAGES
-- ═══════════════════════════════════════════════════════════════
local LANGS = {
    { code="en", flag="🇬🇧", name="English" },
    { code="tr", flag="🇹🇷", name="Türkçe" },
    { code="es", flag="🇪🇸", name="Español" },
    { code="pt", flag="🇧🇷", name="Português" },
    { code="de", flag="🇩🇪", name="Deutsch" },
    { code="fr", flag="🇫🇷", name="Français" },
}

local T = {}
local function aT(k, ...)
    T[k] = {}
    local l = {...}
    for i, L in ipairs(LANGS) do T[k][L.code] = l[i] end
end

aT("nav_dash","Dashboard","Panel","Panel","Painel","Start","Accueil")
aT("nav_farm","AutoFarm","Otomasyon","AutoFarm","AutoFarm","AutoFarm","AutoFarm")
aT("nav_esp","ESP","ESP","ESP","ESP","ESP","ESP")
aT("nav_player","Player","Oyuncu","Jugador","Jogador","Spieler","Joueur")
aT("nav_config","Config","Ayarlar","Ajustes","Config","Einstellungen","Réglages")
aT("nav_debug","Debug","Debug","Debug","Debug","Debug","Debug")

aT("s_master","Master Control","Master Kontrol","Control Maestro","Controle Mestre","Hauptsteuerung","Contrôle Maître")
aT("s_steal","Egg Stealing","Yumurta Çalma","Robo de Huevos","Roubo de Ovos","Ei-Diebstahl","Vol d'Œufs")
aT("s_escape","Escape","Kaçış","Escape","Fuga","Flucht","Évasion")
aT("s_hatch","Hatch","Kuluçka","Eclosionar","Chocar","Brüten","Éclore")
aT("s_safety","Safety","Güvenlik","Seguridad","Segurança","Sicherheit","Sécurité")
aT("s_esp","ESP Filters","ESP Filtreleri","Filtros ESP","Filtros ESP","ESP-Filter","Filtres ESP")
aT("s_ui","Interface","Arayüz","Interfaz","Interface","Oberfläche","Interface")
aT("s_lang","Language","Dil","Idioma","Idioma","Sprache","Langue")
aT("s_profile","Profile","Profil","Perfil","Perfil","Profil","Profil")
aT("s_keys","Keybinds","Kısayollar","Atajos","Atalhos","Tasten","Raccourcis")
aT("s_debug","Debug Console","Debug Konsolu","Consola Debug","Console Debug","Debug-Konsole","Console Debug")
aT("s_anti","Anti-Cheat","Anti-Cheat","Anti-Trampas","Anti-Cheat","Anti-Cheat","Anti-Triche")
aT("s_timing","Timing","Zamanlama","Tiempo","Tempo","Timing","Timing")

aT("t_master","Master AutoFarm","Master Oto-Farm","Auto-Granja","Auto-Fazenda","Meister-Farm","Auto-Ferme")
aT("t_master_d","Enable all modules","Tüm modülleri açar","Activa todo","Ativa tudo","Aktiviert alles","Active tout")
aT("t_steal","Auto Steal Eggs","Oto Yumurta Çal","Robar Huevos","Roubar Ovos","Auto-Eier stehlen","Vol d'Œufs")
aT("t_steal_d","Steals the best eggs nearby","En iyi yumurtaları çalar","Roba los mejores huevos","Rouba os melhores ovos","Stiehlt beste Eier","Vole les meilleurs œufs")
aT("t_return","Auto Return Base","Oto Üsse Dön","Retorno Auto","Retorno Auto","Auto-Rückkehr","Retour Auto")
aT("t_return_d","Returns after stealing","Çaldıktan sonra üsse döner","Regresa tras robar","Retorna após roubar","Kehrt nach Diebstahl zurück","Retour après vol")
aT("t_hatch","Auto Hatch","Oto Kuluçka","Eclosionar Auto","Chocar Auto","Auto-Brüten","Éclore Auto")
aT("t_hatch_d","Hatches ready eggs","Hazır yumurtaları açar","Eclosiona huevos","Choca ovos","Brütet Eier aus","Éclot les œufs")
aT("t_afk","Anti-AFK","Anti-AFK","Anti-AFK","Anti-AFK","Anti-AFK","Anti-AFK")
aT("t_afk_d","Prevents idle kick","Boşta atılmayı engeller","Evita expulsión","Evita kick","Verhindert Idle-Kick","Empêche le kick")
aT("t_noclip","Noclip","Noclip","Noclip","Noclip","Noclip","Noclip")
aT("t_noclip_d","Walk through walls","Duvarlardan geç","Atraviesa paredes","Atravessa paredes","Durch Wände","Traverser murs")
aT("t_esp_egg","Egg ESP","Yumurta ESP","ESP Huevos","ESP Ovos","Ei-ESP","ESP Œufs")
aT("t_esp_egg_d","Highlights unowned eggs","Sahipsiz yumurtaları vurgular","Resalta huevos ajenos","Destaca ovos alheios","Hebt fremde Eier hervor","Surligne les œufs")
aT("t_esp_player","Player ESP","Oyuncu ESP","ESP Jugador","ESP Jogador","Spieler-ESP","ESP Joueur")
aT("t_esp_player_d","Highlights all players","Tüm oyuncuları vurgular","Resalta todos los jugadores","Destaca todos os jogadores","Hebt alle Spieler hervor","Surligne les joueurs")
aT("t_esp_base","Base ESP","Üs ESP","ESP Base","ESP Base","Basis-ESP","ESP Base")
aT("t_esp_base_d","Highlights your base","Üssünü vurgular","Resalta tu base","Destaca sua base","Hebt deine Basis hervor","Surligne ta base")
aT("t_notif","Notifications","Bildirimler","Notificaciones","Notificações","Benachrichtigungen","Notifications")
aT("t_sound","Click Sounds","Tık Sesleri","Sonidos","Sons","Töne","Sons")

aT("btn_collect","STEAL NOW","ŞİMDİ ÇAL","ROBAR AHORA","ROUBAR AGORA","JETZT STEHLEN","VOLER MAINTENANT")
aT("btn_return","RETURN HOME","ÜSSE DÖN","VOLVER A CASA","VOLTAR CASA","NACH HAUSE","RETOUR MAISON")
aT("btn_save","SAVE","KAYDET","GUARDAR","SALVAR","SPEICHERN","ENREGISTRER")
aT("btn_load","LOAD","YÜKLE","CARGAR","CARREGAR","LADEN","CHARGER")
aT("btn_reset","RESET","SIFIRLA","REINICIAR","RESETAR","ZURÜCKSETZEN","RÉINITIALISER")
aT("btn_clear","CLEAR","TEMİZLE","LIMPIAR","LIMPAR","LÖSCHEN","EFFACER")

aT("st_eggs","Eggs Stolen","Çalınan Yumurta","Huevos Robados","Ovos Roubados","Eier gestohlen","Œufs Volés")
aT("st_tries","Attempts","Deneme","Intentos","Tentativas","Versuche","Tentatives")
aT("st_pets","Pets Hatched","Çıkan Pet","Mascotas","Mascotes","Haustiere","Animaux")
aT("st_uptime","Uptime","Süre","Tiempo","Tempo","Laufzeit","Durée")
aT("st_rate","Rate/min","Dakika/Oran","Tasa/min","Taxa/min","Rate/min","Taux/min")

aT("run","Running","Çalışıyor","Ejecutando","Executando","Läuft","En cours")
aT("idle","Idle","Boşta","Inactivo","Inativo","Leerlauf","Inactif")
aT("welcome","Welcome","Hoş geldin","Bienvenido","Bem-vindo","Willkommen","Bienvenue")
aT("loaded","Script loaded successfully","Script yüklendi","Script cargado","Script carregado","Script geladen","Script chargé")
aT("m_on","All modules ON","Tüm modüller AÇIK","Todo ACTIVADO","Tudo ATIVADO","Alle AN","Tous ACTIVÉS")
aT("m_off","All modules OFF","Tüm modüller KAPALI","Todo APAGADO","Tudo DESATIVADO","Alle AUS","Tous DÉSACTIVÉS")
aT("m_lang","Language changed","Dil değişti","Idioma cambiado","Idioma alterado","Sprache geändert","Langue changée")
aT("m_saved","Settings saved","Ayarlar kaydedildi","Ajustes guardados","Config salva","Gespeichert","Enregistré")
aT("m_loaded","Settings loaded","Ayarlar yüklendi","Ajustes cargados","Config carregada","Geladen","Chargé")
aT("m_reset","Reset done","Sıfırlandı","Reiniciado","Resetado","Zurückgesetzt","Réinitialisé")
aT("m_egg","Egg stolen!","Yumurta çalındı!","¡Huevo robado!","Ovo roubado!","Ei gestohlen!","Œuf volé !")
aT("m_nobase","Base not found","Üs bulunamadı","Base no encontrada","Base não encontrada","Basis nicht gefunden","Base introuvable")
aT("m_nobase_tip","Buy a plot first","Önce arsa al","Compra una parcela","Compre um terreno","Erst Feld kaufen","Acheter parcelle")
aT("m_noegg","No eggs nearby","Yakında yumurta yok","Sin huevos cerca","Sem ovos por perto","Keine Eier in der Nähe","Pas d'œufs proches")
aT("dbg_empty","No logs yet","Henüz log yok","Sin logs","Sem logs","Keine Logs","Aucun log")
aT("kb_txt","F1 Panel · F2 Master · F3 Steal · F4 Return · F5 Noclip · F6 ESP","F1 Panel · F2 Master · F3 Çal · F4 Dön · F5 Noclip · F6 ESP","F1 Panel · F2 Master · F3 Robar · F4 Casa · F5 Noclip · F6 ESP","F1 Painel · F2 Master · F3 Roubar · F4 Casa · F5 Noclip · F6 ESP","F1 Panel · F2 Meister · F3 Stehlen · F4 Hause · F5 Noclip · F6 ESP","F1 Panneau · F2 Maître · F3 Voler · F4 Maison · F5 Noclip · F6 ESP")
aT("loading","Loading...","Yükleniyor...","Cargando...","Carregando...","Wird geladen...","Chargement...")
aT("load_modules","Loading modules...","Modüller yükleniyor...","Cargando módulos...","Carregando módulos...","Module werden geladen...","Chargement des modules...")
aT("load_gui","Building interface...","Arayüz hazırlanıyor...","Construyendo interfaz...","Construindo interface...","Oberfläche wird erstellt...","Construction de l'interface...")
aT("load_ready","Ready!","Hazır!","¡Listo!","Pronto!","Bereit!","Prêt !")
aT("search","Search...","Ara...","Buscar...","Buscar...","Suchen...","Rechercher...")

local CurLang = "en"
local function t(k)
    local e = T[k]
    if not e then return k end
    return e[CurLang] or e.en or k
end
local function saveLang(c) if writefile then pcall(writefile, "sv_egg_lang.txt", c) end end
local function loadLang()
    if readfile and isfile and isfile("sv_egg_lang.txt") then
        local ok, c = pcall(readfile, "sv_egg_lang.txt")
        if ok and c then for _, L in ipairs(LANGS) do if L.code == c then return c end end end
    end
    return "en"
end
CurLang = loadLang()

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local CFG = {
    VER = "6.0.2",
    MAX_SPEED = 26, MIN_SPEED = 16,
    SCAN_RADIUS = 500,
    DRAG_PX = 18, TAP = 0.30,
    SCALE = IS_TOUCH and 1.15 or 1.0,
    HUMAN_MIN = 0.08, HUMAN_MAX = 0.35,
    BURST_MIN = 4, BURST_MAX = 6,
    REST_MIN = 8, REST_MAX = 16,
}

local S = {
    masterFarm = false,
    autoSteal = false, autoReturn = false, autoHatch = false,
    espEgg = false, espPlayer = false, espBase = false,
    antiAfk = false, noclip = false,
    notifications = true, clickSound = true,
    walkSpeed = 16,
    btnPos = UDim2.new(0, 20, 0.5, -70),
    stats = { eggs = 0, tries = 0, pets = 0, startTime = os.time() },
}

local DLog = {}
local function dbg(msg, kind)
    table.insert(DLog, { msg = tostring(msg), kind = kind or "info", t = os.time() })
    if #DLog > 100 then table.remove(DLog, 1) end
    LOG(msg)
end
dbg("v6.0 running")

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════
local function mk(cls, props)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do
        pcall(function() i[k] = v end)
    end
    return i
end
local function tw(inst, dur, goal, style, dir)
    if not TS or not inst then return end
    local ok, tween = pcall(function()
        return TS:Create(inst, TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
    end)
    if ok and tween then tween:Play(); return tween end
end
local function twIn(inst, dur, goal, style)
    if not TS or not inst then return end
    local ok, tween = pcall(function()
        return TS:Create(inst, TweenInfo.new(dur, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), goal)
    end)
    if ok and tween then tween:Play(); return tween end
end
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then dbg("ERR: " .. tostring(err), "error") end
    return ok, err
end
local function hrp() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") or nil end
local function hum() local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid") or nil end
local function isClick(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end
local function humanDelay(a, b)
    local r = math.random() * math.random()
    task.wait(a + (b - a) * r)
end
local function fmtTime(s)
    return string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60), s%60)
end
local function humanMove(targetPos)
    local h = hrp()
    if not h or not TS or typeof(targetPos) ~= "Vector3" then return false end
    local d = (targetPos - h.Position).Magnitude
    if d > CFG.SCAN_RADIUS + 100 then return false end
    local dur = math.clamp(d / (CFG.MAX_SPEED * 4), 0.15, 1.4) * (0.85 + math.random() * 0.35)
    local offset = Vector3.new((math.random()-0.5)*3, 0, (math.random()-0.5)*3)
    local ok = pcall(function()
        local tween = TS:Create(h, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            { CFrame = CFrame.new(targetPos + offset + Vector3.new(0, 3, 0)) })
        tween:Play()
        tween.Completed:Wait()
    end)
    task.wait(0.03 + math.random() * 0.05)
    return ok
end

-- ═══════════════════════════════════════════════════════════════
-- SV LOGO
-- ═══════════════════════════════════════════════════════════════
local function drawSVLogo(parent, size)
    size = size or 44
    local wrap = mk("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(0, size, 0, size),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    })
    local hex = mk("Frame", {
        Parent = wrap, BackgroundColor3 = C.primary,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0, ClipsDescendants = true,
    })
    mk("UICorner", { Parent = hex, CornerRadius = UDim.new(0.28, 0) })
    mk("UIGradient", { Parent = hex, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.primary_l),
        ColorSequenceKeypoint.new(0.5, C.primary),
        ColorSequenceKeypoint.new(1, C.violet),
    }), Rotation = 45 })
    mk("Frame", {
        Parent = hex, BackgroundColor3 = C.white, BackgroundTransparency = 0.85,
        Size = UDim2.new(0.85, 0, 0.35, 0),
        Position = UDim2.new(0.5, 0, -0.05, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BorderSizePixel = 0,
    })
    local function bar(pos, sz, rot)
        local f = mk("Frame", {
            Parent = hex, BackgroundColor3 = C.white,
            Size = sz, Position = pos, BorderSizePixel = 0,
            Rotation = rot or 0,
        })
        mk("UICorner", { Parent = f, CornerRadius = UDim.new(1, 0) })
    end
    bar(UDim2.new(0.24, 0, 0.26, 0), UDim2.new(0.42, 0, 0.10, 0))
    bar(UDim2.new(0.24, 0, 0.26, 0), UDim2.new(0.10, 0, 0.20, 0))
    bar(UDim2.new(0.28, 0, 0.45, 0), UDim2.new(0.42, 0, 0.10, 0))
    bar(UDim2.new(0.62, 0, 0.55, 0), UDim2.new(0.10, 0, 0.20, 0))
    bar(UDim2.new(0.28, 0, 0.64, 0), UDim2.new(0.42, 0, 0.10, 0))
    bar(UDim2.new(0.78, 0, 0.26, 0), UDim2.new(0.10, 0, 0.44, 0), 18)
    bar(UDim2.new(0.78, 0, 0.26, 0), UDim2.new(0.10, 0, 0.44, 0), -18)
    mk("UIStroke", { Parent = hex, Color = C.white, Thickness = 2, Transparency = 0.4 })
    return wrap
end

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════
local Notif = {}
Notif.__index = Notif
function Notif.new(parent)
    local self = setmetatable({}, Notif)
    self.c = mk("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 1, -20), Size = UDim2.new(0, 320, 0, 400),
        AnchorPoint = Vector2.new(1, 1), ZIndex = 500,
    })
    mk("UIListLayout", {
        Parent = self.c, SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10),
    })
    return self
end
function Notif:push(title, msg, kind, dur)
    if not S.notifications then return end
    kind = kind or "info"; dur = dur or 3
    local accent = C.primary
    local icon = "i"
    if kind == "success" then accent = C.success; icon = "✓"
    elseif kind == "error" then accent = C.danger; icon = "!"
    elseif kind == "warn" then accent = C.warn; icon = "!" end

    local wrap = mk("Frame", {
        Parent = self.c, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 78), ZIndex = 501,
    })
    local shadow = mk("Frame", {
        Parent = wrap, BackgroundColor3 = C.shadow, BackgroundTransparency = 0.9,
        BorderSizePixel = 0, Position = UDim2.new(0, 2, 0, 4),
        Size = UDim2.new(1, -4, 1, -4), ZIndex = 501,
    })
    mk("UICorner", { Parent = shadow, CornerRadius = UDim.new(0, 14) })

    local f = mk("Frame", {
        Parent = wrap, BackgroundColor3 = C.white, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), ClipsDescendants = true, ZIndex = 502,
    })
    mk("UICorner", { Parent = f, CornerRadius = UDim.new(0, 14) })
    mk("UIStroke", { Parent = f, Color = C.border, Thickness = 1, Transparency = 0.3 })
    mk("Frame", { Parent = f, BackgroundColor3 = accent, Size = UDim2.new(0, 4, 1, 0), BorderSizePixel = 0, ZIndex = 503 })

    local iconBg = mk("Frame", { Parent = f, BackgroundColor3 = accent,
        Position = UDim2.new(0, 14, 0, 22), Size = UDim2.new(0, 34, 0, 34),
        BorderSizePixel = 0, ZIndex = 503 })
    mk("UICorner", { Parent = iconBg, CornerRadius = UDim.new(1, 0) })
    mk("TextLabel", { Parent = iconBg, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold, Text = icon, TextColor3 = C.white, TextSize = 18, ZIndex = 504 })

    mk("TextLabel", { Parent = f, BackgroundTransparency = 1,
        Position = UDim2.new(0, 58, 0, 14), Size = UDim2.new(1, -72, 0, 20),
        Font = Enum.Font.GothamBold, Text = title, TextColor3 = C.text,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 503 })
    mk("TextLabel", { Parent = f, BackgroundTransparency = 1,
        Position = UDim2.new(0, 58, 0, 36), Size = UDim2.new(1, -72, 0, 34),
        Font = Enum.Font.Gotham, Text = msg, TextColor3 = C.text_mut,
        TextSize = 11, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 503 })

    wrap.Position = UDim2.new(1, 40, 0, 0)
    tw(wrap, 0.4, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
    task.delay(dur, function()
        if wrap.Parent then
            tw(wrap, 0.3, { Position = UDim2.new(1, 40, 0, 0) }, Enum.EasingStyle.Quint)
            task.wait(0.35)
            pcall(function() wrap:Destroy() end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- GAME HOOKS
-- ═══════════════════════════════════════════════════════════════
local Refs = { myBase = nil, stealR = {}, sellR = {}, hatchR = {} }

local function findMyBase()
    if not WS then return false end
    for _, obj in ipairs(WS:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local ov = obj:FindFirstChild("Owner")
            if ov and ov:IsA("ObjectValue") and ov.Value == LP then
                Refs.myBase = obj
                dbg("Base: " .. obj.Name, "success")
                return true
            end
            local att = obj:GetAttribute("Owner")
            if att == LP.Name or att == LP.UserId or att == tostring(LP.UserId) then
                Refs.myBase = obj
                dbg("Base (attr): " .. obj.Name, "success")
                return true
            end
            if obj.Name:find(LP.Name, 1, true) then
                Refs.myBase = obj
                dbg("Base (name): " .. obj.Name, "success")
                return true
            end
        end
    end
    return false
end

local function findRemotes()
    Refs.stealR, Refs.sellR, Refs.hatchR = {}, {}, {}
    if not RS then return end

    local folders = {
        RS:FindFirstChild("Remotes"),
        RS:FindFirstChild("RemoteEvents"),
        RS:FindFirstChild("Networking"),
        RS,
    }
    local seenContainers, seenRemotes = {}, {}

    for _, f in ipairs(folders) do
        if f and not seenContainers[f] then
            seenContainers[f] = true
            for _, r in ipairs(f:GetDescendants()) do
                if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and not seenRemotes[r] then
                    seenRemotes[r] = true
                    local n = r.Name:lower()
                    if n:find("steal") or n:find("grab") or n:find("pickup") or n:find("collect") then
                        table.insert(Refs.stealR, r)
                    elseif n:find("sell") then
                        table.insert(Refs.sellR, r)
                    elseif n:find("hatch") or n:find("open") then
                        table.insert(Refs.hatchR, r)
                    end
                end
            end
        end
    end
    dbg(string.format("Remotes: steal=%d sell=%d hatch=%d",
        #Refs.stealR, #Refs.sellR, #Refs.hatchR))
end

local function isMyEgg(o)
    local owner = o:GetAttribute("Owner")
    if owner == LP or owner == LP.Name or owner == LP.UserId then
        return true
    end

    local ownerObj = o:FindFirstChild("Owner")
    if ownerObj then
        local ok, value = pcall(function()
            return ownerObj.Value
        end)
        if ok and (value == LP or value == LP.Name or value == LP.UserId) then
            return true
        end
    end

    return false
end

local function findEggs()
    local h = hrp()
    if not h then return {} end
    local list = {}
    for _, o in ipairs(WS:GetDescendants()) do
        if o:IsA("Model") or o:IsA("BasePart") then
            local n = (o.Name or ""):lower()
            if n:find("egg") and not isMyEgg(o) then
                if not (o:GetAttribute("Claimed") or o:GetAttribute("Stolen") or o:GetAttribute("Taken")) then
                    local p = o:IsA("BasePart") and o or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart", true)
                    if p then
                        local d = (p.Position - h.Position).Magnitude
                        if d <= CFG.SCAN_RADIUS then
                            table.insert(list, { obj = o, part = p, dist = d })
                        end
                    end
                end
            end
        end
    end
    -- Fisher-Yates shuffle
    for i = #list, 2, -1 do
        local j = math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
    -- Sort by distance
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function stealOne(egg)
    if type(egg) ~= "table" or not egg.obj or not egg.part then
        return false
    end
    if not egg.obj.Parent or not egg.part.Parent then
        return false
    end

    S.stats.tries = S.stats.tries + 1
    if not humanMove(egg.part.Position) then
        return false
    end
    humanDelay(CFG.HUMAN_MIN, 0.22)
    local h = hrp()
    local part = egg.part
    local obj = egg.obj

    if firetouchinterest and h and part then
        pcall(function()
            firetouchinterest(h, part, 0)
            task.wait(0.03)
            firetouchinterest(h, part, 1)
        end)
    end
    pcall(function()
        local pp = obj:FindFirstChildOfClass("ProximityPrompt")
            or (part and part:FindFirstChildOfClass("ProximityPrompt"))
        if pp and pp.Enabled then fireproximityprompt(pp) end
    end)
    pcall(function()
        local cd = obj:FindFirstChildOfClass("ClickDetector")
            or (part and part:FindFirstChildOfClass("ClickDetector"))
        if cd then fireclickdetector(cd) end
    end)
    for _, r in ipairs(Refs.stealR) do
        pcall(function()
            if r:IsA("RemoteEvent") then r:FireServer(obj)
            else r:InvokeServer(obj) end
        end)
        break
    end
    task.wait(0.15 + math.random() * 0.10)

    S.stats.eggs = S.stats.eggs + 1
    dbg("Egg stolen!", "success")
    return true
end

local function returnHome()
    if not Refs.myBase then findMyBase() end
    if not Refs.myBase then return false end
    local pos
    if Refs.myBase:IsA("Model") then
        local ok, pivot = pcall(function() return Refs.myBase:GetPivot() end)
        if ok and pivot then pos = pivot.Position end
    elseif Refs.myBase:IsA("BasePart") then
        pos = Refs.myBase.Position
    end
    if not pos then
        local bp = Refs.myBase:FindFirstChildWhichIsA("BasePart")
        if bp then pos = bp.Position end
    end
    if not pos then return false end
    humanMove(pos)
    return true
end

local function doHatch()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, g in ipairs(pg:GetDescendants()) do
        if (g:IsA("TextButton") or g:IsA("ImageButton")) and g.Visible then
            local txt = g:IsA("TextButton") and g.Text:lower() or ""
            if txt:find("hatch") or txt:find("open") then
                pcall(function() g:Activate() end)
                S.stats.pets = S.stats.pets + 1
                task.wait(0.3)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FARM LOOP
-- ═══════════════════════════════════════════════════════════════
local Farm = { running = false, thread = nil, onStatus = nil }

function Farm:start()
    if self.running then return end
    self.running = true
    if self.onStatus then pcall(self.onStatus, true) end
    dbg("Farm started", "success")
    self.thread = task.spawn(function()
        local burstGoal = math.random(CFG.BURST_MIN, CFG.BURST_MAX)
        local burstCount = 0
        while self.running do
            pcall(function()
                if not hrp() then
                    task.wait(0.5)
                    return
                end
                if tick() - (self.lastScan or 0) > 8 then
                    self.lastScan = tick()
                    pcall(findMyBase)
                    pcall(findRemotes)
                end
                if S.masterFarm or S.autoSteal then
                    local eggs = findEggs()
                    if #eggs > 0 then
                        if stealOne(eggs[1]) then
                            burstCount = burstCount + 1
                            humanDelay(0.15, 0.45)
                        else
                            task.wait(1 + math.random())
                        end
                        if burstCount >= burstGoal then
                            if S.autoReturn or S.masterFarm then returnHome() end
                            local rest = CFG.REST_MIN + math.random() * (CFG.REST_MAX - CFG.REST_MIN)
                            task.wait(rest)
                            burstGoal = math.random(CFG.BURST_MIN, CFG.BURST_MAX)
                            burstCount = 0
                        end
                    else
                        task.wait(1.5 + math.random())
                    end
                end
                if S.masterFarm or S.autoHatch then doHatch() end
            end)
            task.wait(0.15 + math.random() * 0.15)
        end
    end)
end

function Farm:stop()
    self.running = false
    if self.thread then
        pcall(task.cancel, self.thread)
        self.thread = nil
    end
    if self.onStatus then pcall(self.onStatus, false) end
    dbg("Farm stopped")
end

local toggles = {}

local function farmShouldRun()
    return S.masterFarm or S.autoSteal or S.autoHatch
end

local function syncFarm()
    if farmShouldRun() then
        Farm:start()
    else
        Farm:stop()
    end
end

function Farm:toggle()
    if self.running then
        self:stop()
        S.masterFarm = false
        for _, k in ipairs({"autoSteal","autoReturn","autoHatch"}) do
            S[k] = false
            if toggles[k] then toggles[k](false, true) end
        end
        return false
    end

    S.masterFarm = true
    for _, k in ipairs({"autoSteal","autoReturn","autoHatch"}) do
        S[k] = true
        if toggles[k] then toggles[k](true, true) end
    end
    syncFarm()
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- ESP LOOP
-- ═══════════════════════════════════════════════════════════════
local ESP_FOLDER = Instance.new("Folder")
ESP_FOLDER.Name = "ScriptVault_ESP"
pcall(function()
    local old = WS:FindFirstChild("ScriptVault_ESP")
    if old then old:Destroy() end
    ESP_FOLDER.Parent = WS
end)

local function clearESP(kind)
    for _, child in ipairs(ESP_FOLDER:GetChildren()) do
        if not kind or child.Name == kind then
            pcall(function() child:Destroy() end)
        end
    end
end

local function cleanStaleESP(kind)
    for _, child in ipairs(ESP_FOLDER:GetChildren()) do
        if child.Name == kind and (not child.Adornee or not child.Adornee.Parent) then
            pcall(function() child:Destroy() end)
        end
    end
end

task.spawn(function()
    while isCurrentRuntime() do
        pcall(function()
            if S.espEgg then
                cleanStaleESP("SV_ESP_EGG")
                local eggs = findEggs()
                for _, egg in ipairs(eggs) do
                    local target = egg.obj
                    local exists = false
                    for _, hl in ipairs(ESP_FOLDER:GetChildren()) do
                        if hl.Name == "SV_ESP_EGG" and hl.Adornee == target then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        local hl = Instance.new("Highlight")
                        hl.Name = "SV_ESP_EGG"
                        hl.Adornee = target
                        hl.FillColor = C.gold
                        hl.FillTransparency = 0.55
                        hl.OutlineColor = C.white
                        hl.OutlineTransparency = 0.15
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = ESP_FOLDER
                    end
                end
            else
                clearESP("SV_ESP_EGG")
            end

            if S.espPlayer then
                cleanStaleESP("SV_ESP_PLAYER")
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LP and pl.Character then
                        local target = pl.Character
                        local exists = false
                        for _, hl in ipairs(ESP_FOLDER:GetChildren()) do
                            if hl.Name == "SV_ESP_PLAYER" and hl.Adornee == target then
                                exists = true
                                break
                            end
                        end
                        if not exists then
                            local hl = Instance.new("Highlight")
                            hl.Name = "SV_ESP_PLAYER"
                            hl.Adornee = target
                            hl.FillColor = C.danger
                            hl.FillTransparency = 0.65
                            hl.OutlineColor = C.white
                            hl.OutlineTransparency = 0.2
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = ESP_FOLDER
                        end
                    end
                end
            else
                clearESP("SV_ESP_PLAYER")
            end

            if S.espBase and Refs.myBase then
                cleanStaleESP("SV_ESP_BASE")
                local target = Refs.myBase
                if not target:IsA("Model") and not target:IsA("BasePart") then
                    target = target:FindFirstChildWhichIsA("BasePart", true)
                end
                if target then
                    local exists = false
                    for _, hl in ipairs(ESP_FOLDER:GetChildren()) do
                        if hl.Name == "SV_ESP_BASE" and hl.Adornee == target then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        local hl = Instance.new("Highlight")
                        hl.Name = "SV_ESP_BASE"
                        hl.Adornee = target
                        hl.FillColor = C.success
                        hl.FillTransparency = 0.75
                        hl.OutlineColor = C.success
                        hl.OutlineTransparency = 0.15
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = ESP_FOLDER
                    end
                end
            else
                clearESP("SV_ESP_BASE")
            end
        end)
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- PLAYER LOOPS
-- ═══════════════════════════════════════════════════════════════
LP.Idled:Connect(function()
    if not isCurrentRuntime() then return end
    if S.antiAfk and VirtualUser then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

local noclipOriginal = {}

task.spawn(function()
    while isCurrentRuntime() do
        if S.noclip then
            local c = LP.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then
                        if noclipOriginal[p] == nil then
                            noclipOriginal[p] = p.CanCollide
                        end
                        if p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end
            end
        else
            for p, original in pairs(noclipOriginal) do
                if p and p.Parent then
                    p.CanCollide = original
                end
                noclipOriginal[p] = nil
            end
        end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while isCurrentRuntime() do
        local h = hum()
        if h then
            local target = math.clamp(S.walkSpeed, CFG.MIN_SPEED, 200)
            if h.WalkSpeed ~= target then h.WalkSpeed = target end
        end
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- UI COMPONENTS
-- ═══════════════════════════════════════════════════════════════
local U = {}

function U.card(parent, height)
    local wrap = mk("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height + 6), ZIndex = 9002,
    })
    local sh = mk("Frame", {
        Parent = wrap, BackgroundColor3 = C.shadow, BackgroundTransparency = 0.93,
        BorderSizePixel = 0, Position = UDim2.new(0, 2, 0, 4),
        Size = UDim2.new(1, -4, 0, height), ZIndex = 9001,
    })
    mk("UICorner", { Parent = sh, CornerRadius = UDim.new(0, 14) })
    local card = mk("Frame", {
        Parent = wrap, BackgroundColor3 = C.card, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height), ZIndex = 9002,
    })
    mk("UICorner", { Parent = card, CornerRadius = UDim.new(0, 16) })
    mk("UIGradient", { Parent = card, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.card),
        ColorSequenceKeypoint.new(1, C.bg_deep),
    }), Rotation = 90 })
    mk("UIStroke", { Parent = card, Color = C.border, Thickness = 1, Transparency = 0.25 })
    return wrap, card
end

function U.section(parent, key, accent)
    accent = accent or C.primary
    local w = mk("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28), ZIndex = 9002,
    })
    local bar = mk("Frame", {
        Parent = w, BackgroundColor3 = accent,
        Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(0, 3, 0, 16),
        AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = bar, CornerRadius = UDim.new(1, 0) })
    local l = mk("TextLabel", {
        Parent = w, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.GothamBold, Text = t(key):upper(),
        TextColor3 = C.text_mut, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9003,
    })
    l:SetAttribute("i18n", key)
    return w
end

function U.toggle(parent, nameKey, descKey, stateKey, onChange, reg)
    local h = descKey and (62 * CFG.SCALE) or (52 * CFG.SCALE)
    local wrap, card = U.card(parent, h)

    local iconBg = mk("Frame", {
        Parent = card,
        BackgroundColor3 = S[stateKey] and C.primary or C.card_alt,
        Position = UDim2.new(0, 12, 0, (h - 36) / 2),
        Size = UDim2.new(0, 36, 0, 36),
        BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = iconBg, CornerRadius = UDim.new(0, 10) })
    local icon = mk("TextLabel", {
        Parent = iconBg, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = S[stateKey] and "✓" or "○",
        TextColor3 = S[stateKey] and C.white or C.text_dim,
        TextSize = 16, ZIndex = 9004,
    })

    local name = mk("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 58, 0, descKey and 10 or (h - 18) / 2),
        Size = UDim2.new(1, -130, 0, 18),
        Font = Enum.Font.GothamMedium, Text = t(nameKey),
        TextColor3 = C.text, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9003,
    })
    name:SetAttribute("i18n", nameKey)

    if descKey then
        local d = mk("TextLabel", {
            Parent = card, BackgroundTransparency = 1,
            Position = UDim2.new(0, 58, 0, 30), Size = UDim2.new(1, -130, 0, 24),
            Font = Enum.Font.Gotham, Text = t(descKey),
            TextColor3 = C.text_mut, TextSize = 10, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9003,
        })
        d:SetAttribute("i18n", descKey)
    end

    local tw_ = 52 * CFG.SCALE
    local th = 30 * CFG.SCALE
    local track = mk("TextButton", {
        Parent = card,
        BackgroundColor3 = S[stateKey] and C.primary or C.border_h,
        Position = UDim2.new(1, -tw_ - 12, 0.5, -th / 2),
        Size = UDim2.new(0, tw_, 0, th),
        Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = track, CornerRadius = UDim.new(1, 0) })
    local kd = 24 * CFG.SCALE
    local knob = mk("Frame", {
        Parent = track, BackgroundColor3 = C.white,
        Position = S[stateKey] and UDim2.new(1, -kd - 3, 0.5, -kd / 2) or UDim2.new(0, 3, 0.5, -kd / 2),
        Size = UDim2.new(0, kd, 0, kd),
        BorderSizePixel = 0, ZIndex = 9004,
    })
    mk("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })
    mk("UIStroke", { Parent = knob, Color = C.border, Thickness = 1, Transparency = 0.5 })

    local function apply(on, silent)
        S[stateKey] = on
        tw(track, 0.25, { BackgroundColor3 = on and C.primary or C.border_h }, Enum.EasingStyle.Quint)
        twIn(knob, 0.28, { Position = on and UDim2.new(1, -kd - 3, 0.5, -kd / 2) or UDim2.new(0, 3, 0.5, -kd / 2) }, Enum.EasingStyle.Back)
        tw(iconBg, 0.2, { BackgroundColor3 = on and C.primary or C.card_alt })
        icon.Text = on and "✓" or "○"
        icon.TextColor3 = on and C.white or C.text_dim
        if onChange and not silent then onChange(on) end
    end
    track.Activated:Connect(function() apply(not S[stateKey], false) end)
    card.MouseEnter:Connect(function() tw(card, 0.15, { BackgroundColor3 = C.hover }) end)
    card.MouseLeave:Connect(function() tw(card, 0.15, { BackgroundColor3 = C.card }) end)
    if reg then
        local previous = reg[stateKey]
        if previous then
            reg[stateKey] = function(on, silent)
                previous(on, silent)
                apply(on, silent)
            end
        else
            reg[stateKey] = apply
        end
    end
    return wrap
end

function U.button(parent, textKey, variant, onClick)
    variant = variant or "primary"
    local colors
    if variant == "primary" then colors = { C.primary, C.accent, C.white }
    elseif variant == "success" then colors = { C.success, C.success_d, C.white }
    elseif variant == "danger" then colors = { C.danger, Color3.fromRGB(220, 38, 38), C.white }
    elseif variant == "ghost" then colors = { C.card_alt, C.border, C.text }
    elseif variant == "gold" then colors = { C.gold, C.warn, C.text }
    end

    local h = 46 * CFG.SCALE
    local wrap, card = U.card(parent, h)
    local btn = mk("TextButton", {
        Parent = card, BackgroundColor3 = colors[1],
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold, Text = t(textKey),
        TextColor3 = colors[3], TextSize = 13,
        AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 9003,
    })
    btn:SetAttribute("i18n", textKey)
    mk("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 12) })
    if variant ~= "ghost" then
        mk("UIGradient", { Parent = btn, Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colors[1]),
            ColorSequenceKeypoint.new(1, colors[2]),
        }), Rotation = 15 })
    end

    btn.MouseEnter:Connect(function()
        tw(btn, 0.15, { Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0, -2, 0, -2) })
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, 0.15, { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0) })
    end)
    btn.Activated:Connect(function() safe(onClick) end)
    return wrap
end

function U.stat(parent, labelKey, valFn, color, isTime)
    color = color or C.primary
    local h = 76
    local wrap, card = U.card(parent, h)
    mk("Frame", {
        Parent = card, BackgroundColor3 = color,
        Size = UDim2.new(0, 4, 1, 0), BorderSizePixel = 0, ZIndex = 9003,
    })
    local lbl = mk("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -30, 0, 14),
        Font = Enum.Font.GothamBold, Text = t(labelKey):upper(),
        TextColor3 = C.text_mut, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9003,
    })
    lbl:SetAttribute("i18n", labelKey)

    local v = mk("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 26), Size = UDim2.new(1, -30, 0, 36),
        Font = Enum.Font.GothamBold, Text = "0",
        TextColor3 = C.text, TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9003,
    })
    task.spawn(function()
        while card.Parent do
            local ok, val = pcall(valFn)
            if ok then
                if isTime and type(val) == "number" then
                    v.Text = fmtTime(val)
                else
                    v.Text = tostring(val)
                end
            end
            task.wait(0.5)
        end
    end)
    return wrap
end

-- ═══════════════════════════════════════════════════════════════
-- BUILD PANEL
-- ═══════════════════════════════════════════════════════════════
local hiddenRef = { fn = nil }
local rebuildRef = { fn = nil }

local function buildPanel(parent, notif)
    local W = IS_TOUCH and 440 or 420
    local H = IS_TOUCH and 640 or 620

    local panel = mk("Frame", {
        Parent = parent, BackgroundColor3 = C.bg, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 26, 0.5, 0),
        Size = UDim2.new(0, W, 0, H), Visible = false, ZIndex = 9000,
    })
    local panelShadow = mk("Frame", {
        Parent = panel, BackgroundColor3 = C.shadow, BackgroundTransparency = 0.82,
        Position = UDim2.new(0, 8, 0, 10), Size = UDim2.new(1, -16, 1, -8),
        BorderSizePixel = 0, ZIndex = 8999,
    })
    mk("UICorner", { Parent = panelShadow, CornerRadius = UDim.new(0, 24) })
    mk("UICorner", { Parent = panel, CornerRadius = UDim.new(0, 22) })
    mk("UIStroke", { Parent = panel, Color = C.border, Thickness = 1, Transparency = 0.3 })

    -- TOP BAR
    local topBar = mk("Frame", {
        Parent = panel, BackgroundColor3 = C.white,
        Size = UDim2.new(1, 0, 0, 68), BorderSizePixel = 0,
        ZIndex = 9001, ClipsDescendants = true,
    })
    mk("UICorner", { Parent = topBar, CornerRadius = UDim.new(0, 22) })
    mk("Frame", {
        Parent = topBar, BackgroundColor3 = C.white,
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0.5, 0),
        BorderSizePixel = 0, ZIndex = 9001,
    })
    mk("Frame", {
        Parent = topBar, BackgroundColor3 = C.border,
        Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0, ZIndex = 9002,
    })

    -- Logo
    local logoHolder = mk("Frame", {
        Parent = topBar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.new(0, 42, 0, 42),
        AnchorPoint = Vector2.new(0, 0.5), ZIndex = 9003,
    })
    drawSVLogo(logoHolder, 42)

    local dot = mk("Frame", {
        Parent = logoHolder, BackgroundColor3 = C.success,
        Position = UDim2.new(1, -10, 1, -10), Size = UDim2.new(0, 12, 0, 12),
        BorderSizePixel = 0, ZIndex = 9005,
    })
    mk("UICorner", { Parent = dot, CornerRadius = UDim.new(1, 0) })
    mk("UIStroke", { Parent = dot, Color = C.white, Thickness = 2 })

    local uname = LP.DisplayName ~= "" and LP.DisplayName or LP.Name
    if #uname > 14 then uname = string.sub(uname, 1, 14) .. "..." end
    mk("TextLabel", {
        Parent = topBar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 66, 0, 16), Size = UDim2.new(1, -180, 0, 20),
        Font = Enum.Font.GothamBold, Text = uname,
        TextColor3 = C.text, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9003,
    })
    local subInfo = mk("TextLabel", {
        Parent = topBar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 66, 0, 38), Size = UDim2.new(1, -180, 0, 16),
        Font = Enum.Font.GothamMedium, Text = "● " .. t("idle"),
        TextColor3 = C.text_mut, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9003,
    })

    local langBtn = mk("TextButton", {
        Parent = topBar, BackgroundColor3 = C.sky,
        Position = UDim2.new(1, -110, 0.5, 0), Size = UDim2.new(0, 42, 0, 34),
        AnchorPoint = Vector2.new(0, 0.5), Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = langBtn, CornerRadius = UDim.new(0, 10) })
    local langFlag = mk("TextLabel", {
        Parent = langBtn, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold, Text = "🌐",
        TextColor3 = C.primary_d, TextSize = 18, ZIndex = 9004,
    })
    local function updFlag()
        for _, L in ipairs(LANGS) do
            if L.code == CurLang then langFlag.Text = L.flag; return end
        end
    end
    updFlag()

    local closeBtn = mk("TextButton", {
        Parent = topBar, BackgroundColor3 = C.danger_l,
        Position = UDim2.new(1, -60, 0.5, 0), Size = UDim2.new(0, 34, 0, 34),
        AnchorPoint = Vector2.new(0, 0.5), Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = closeBtn, CornerRadius = UDim.new(0, 10) })
    for _, rot in ipairs({ 45, -45 }) do
        local b = mk("Frame", {
            Parent = closeBtn, BackgroundColor3 = C.danger,
            Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 14, 0, 2),
            AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
            Rotation = rot, ZIndex = 9004,
        })
        mk("UICorner", { Parent = b, CornerRadius = UDim.new(1, 0) })
    end

    -- TABS
    local tabBar = mk("Frame", {
        Parent = panel, BackgroundColor3 = C.card_alt,
        Position = UDim2.new(0, 12, 0, 78), Size = UDim2.new(1, -24, 0, 42),
        BorderSizePixel = 0, ZIndex = 9002,
    })
    mk("UICorner", { Parent = tabBar, CornerRadius = UDim.new(0, 12) })
    mk("UIStroke", { Parent = tabBar, Color = C.border, Thickness = 1, Transparency = 0.5 })

    local pages, navBtns, active = {}, {}, nil
    local ind = mk("Frame", {
        Parent = tabBar, BackgroundColor3 = C.primary,
        Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(0, 0, 1, -8),
        BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = ind, CornerRadius = UDim.new(0, 9) })
    mk("UIGradient", { Parent = ind, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.primary),
        ColorSequenceKeypoint.new(1, C.accent),
    }), Rotation = 15 })

    local content = mk("Frame", {
        Parent = panel, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 130), Size = UDim2.new(1, 0, 1, -168),
        ZIndex = 9001,
    })

    local tabList = {
        { id = "dash",   label = "nav_dash",   icon = "◆" },
        { id = "farm",   label = "nav_farm",   icon = "❖" },
        { id = "esp",    label = "nav_esp",    icon = "◎" },
        { id = "player", label = "nav_player", icon = "♟" },
        { id = "config", label = "nav_config", icon = "⚙" },
        { id = "debug",  label = "nav_debug",  icon = "◇" },
    }
    local tabW = (W - 24 - 8) / #tabList
    ind.Size = UDim2.new(0, tabW - 2, 1, -8)

    local function switchTab(id, idx)
        if active == id then return end
        for _, p in pairs(pages) do p.Visible = false end
        if pages[id] then pages[id].Visible = true end
        for tid, b in pairs(navBtns) do
            local on = tid == id
            b.TextColor3 = on and C.white or C.text_mut
            b.BackgroundTransparency = on and 0 or 1
            local ic = b:FindFirstChild("TabIcon")
            if ic then ic.TextColor3 = on and C.white or C.text_mut end
            local lbl = b:FindFirstChild("TabLabel")
            if lbl then lbl.TextColor3 = on and C.white or C.text_mut end
        end
        twIn(ind, 0.28, { Position = UDim2.new(0, 4 + (idx - 1) * (tabW + 2), 0, 4) }, Enum.EasingStyle.Quint)
        active = id
    end

    for idx, tb in ipairs(tabList) do
        local b = mk("TextButton", {
            Parent = tabBar, BackgroundTransparency = 1,
            Position = UDim2.new(0, 4 + (idx - 1) * (tabW + 2), 0.5, 0),
            Size = UDim2.new(0, tabW - 2, 0, 34),
            AnchorPoint = Vector2.new(0, 0.5), Text = "",
            AutoButtonColor = false, ZIndex = 9004,
        })
        mk("UICorner", { Parent = b, CornerRadius = UDim.new(0, 9) })
        local ic = mk("TextLabel", {
            Parent = b, BackgroundTransparency = 1,
            Position = UDim2.new(0, 6, 0, 4), Size = UDim2.new(0, 16, 0, 16),
            Font = Enum.Font.GothamBold, Text = tb.icon,
            TextColor3 = C.text_mut, TextSize = 12, ZIndex = 9005,
        })
        ic.Name = "TabIcon"
        local lbl = mk("TextLabel", {
            Parent = b, BackgroundTransparency = 1,
            Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -28, 1, 0),
            Font = Enum.Font.GothamBold, Text = t(tb.label),
            TextColor3 = C.text_mut, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9005,
        })
        lbl.Name = "TabLabel"
        lbl:SetAttribute("i18n", tb.label)
        b.MouseEnter:Connect(function()
            if active ~= tb.id then
                tw(b, 0.15, { BackgroundColor3 = C.hover, BackgroundTransparency = 0.15 })
            end
        end)
        b.MouseLeave:Connect(function()
            if active ~= tb.id then
                tw(b, 0.15, { BackgroundTransparency = 1 })
            end
        end)
        b.Activated:Connect(function() switchTab(tb.id, idx) end)
        navBtns[tb.id] = b

        local page = mk("ScrollingFrame", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), Visible = false,
            ScrollBarThickness = 4, ScrollBarImageColor3 = C.border_h,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 9001,
        })
        mk("UIListLayout", { Parent = page, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
        mk("UIPadding", { Parent = page,
            PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 16) })
        pages[tb.id] = page
    end

    -- DASH
    local dp = pages.dash
    U.stat(dp, "st_eggs", function() return S.stats.eggs end, C.gold)
    U.stat(dp, "st_tries", function() return S.stats.tries end, C.primary)
    U.stat(dp, "st_pets", function() return S.stats.pets end, C.success)
    U.stat(dp, "st_uptime", function() return os.time() - S.stats.startTime end, C.text_mut, true)

    -- LIVE CONTROL CARD
    local liveWrap, liveCard = U.card(dp, 92)
    liveCard.BackgroundColor3 = C.bg_deep
    local liveGradient = mk("UIGradient", { Parent = liveCard, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.bg_deep),
        ColorSequenceKeypoint.new(0.65, C.card_alt),
        ColorSequenceKeypoint.new(1, C.sky),
    }), Rotation = 20 })
    local liveAccent = mk("Frame", {
        Parent = liveCard, BackgroundColor3 = C.primary,
        Size = UDim2.new(0, 4, 1, 0), BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = liveAccent, CornerRadius = UDim.new(1, 0) })
    local liveTitle = mk("TextLabel", {
        Parent = liveCard, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -32, 0, 18),
        Font = Enum.Font.GothamBold, Text = "LIVE CONTROL CENTER",
        TextColor3 = C.text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9004,
    })
    local livePulse = mk("Frame", {
        Parent = liveCard, BackgroundColor3 = C.primary_l, BackgroundTransparency = 0.88,
        Position = UDim2.new(1, -120, 0, 10), Size = UDim2.new(0, 96, 0, 72),
        BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = livePulse, CornerRadius = UDim.new(1, 0) })
    local liveState = mk("TextLabel", {
        Parent = liveCard, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 34), Size = UDim2.new(0.55, 0, 0, 20),
        Font = Enum.Font.GothamBold, Text = "● IDLE", TextColor3 = C.text_mut,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9004,
    })
    local liveMeta = mk("TextLabel", {
        Parent = liveCard, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 57), Size = UDim2.new(0.6, 0, 0, 16),
        Font = Enum.Font.Gotham, Text = "Eggs 0  •  Tries 0", TextColor3 = C.text_dim,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9004,
    })
    local quick = mk("TextButton", {
        Parent = liveCard, BackgroundColor3 = C.primary,
        Position = UDim2.new(1, -106, 0.5, 0), Size = UDim2.new(0, 92, 0, 34),
        AnchorPoint = Vector2.new(0, 0.5), Text = "START FARM",
        Font = Enum.Font.GothamBold, TextColor3 = C.white, TextSize = 10,
        AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 9004,
    })
    mk("UICorner", { Parent = quick, CornerRadius = UDim.new(0, 10) })
    quick.MouseEnter:Connect(function()
        tw(quick, 0.15, { Size = UDim2.new(0, 98, 0, 38), Position = UDim2.new(1, -109, 0.5, 0) })
    end)
    quick.MouseLeave:Connect(function()
        tw(quick, 0.15, { Size = UDim2.new(0, 92, 0, 34), Position = UDim2.new(1, -106, 0.5, 0) })
    end)
    quick.Activated:Connect(function()
        local on = not S.masterFarm
        S.masterFarm = on
        if toggles.masterFarm then toggles.masterFarm(on, true) end
        for _, k in ipairs({"autoSteal", "autoReturn", "autoHatch"}) do
            S[k] = on
            if toggles[k] then toggles[k](on, true) end
        end
        syncFarm()
    end)
    task.spawn(function()
        while liveCard.Parent do
            local running = S.masterFarm or S.autoSteal or S.autoHatch
            liveState.Text = running and "● RUNNING" or "● IDLE"
            liveState.TextColor3 = running and C.success or C.text_mut
            liveAccent.BackgroundColor3 = running and C.success or C.primary
            livePulse.BackgroundColor3 = running and C.success_l or C.primary_l
            livePulse.BackgroundTransparency = running and 0.82 or 0.9
            quick.Text = running and "STOP FARM" or "START FARM"
            quick.BackgroundColor3 = running and C.danger or C.primary
            liveMeta.Text = string.format("Eggs %d  •  Tries %d  •  Pets %d", S.stats.eggs, S.stats.tries, S.stats.pets)
            task.wait(0.5)
        end
    end)

    U.section(dp, "s_master", C.primary)
    U.toggle(dp, "t_master", "t_master_d", "masterFarm", function(on)
        local list = {"autoSteal","autoReturn","autoHatch"}
        for _, k in ipairs(list) do
            S[k] = on
            if toggles[k] then toggles[k](on, true) end
        end
        if on then Farm:start() else Farm:stop() end
        notif:push(t("s_master"), on and t("m_on") or t("m_off"),
            on and "success" or "warn", 2)
    end, toggles)

    U.section(dp, "s_steal", C.warn)
    U.toggle(dp, "t_steal", "t_steal_d", "autoSteal", function() syncFarm() end, toggles)
    U.toggle(dp, "t_return", "t_return_d", "autoReturn", function() syncFarm() end, toggles)
    U.toggle(dp, "t_hatch", "t_hatch_d", "autoHatch", function() syncFarm() end, toggles)

    U.section(dp, "s_escape", C.accent)
    U.button(dp, "btn_collect", "primary", function()
        local eggs = findEggs()
        if #eggs > 0 then
            stealOne(eggs[1])
            notif:push(t("s_steal"), t("m_egg"), "success", 2)
        else
            notif:push(t("s_steal"), t("m_noegg"), "warn", 2)
        end
    end)
    U.button(dp, "btn_return", "success", function()
        if returnHome() then
            notif:push(t("s_escape"), "OK", "success", 2)
        else
            notif:push(t("s_escape"), t("m_nobase"), "warn", 2)
        end
    end)

    -- FARM
    local fp = pages.farm
    U.section(fp, "s_steal", C.warn)
    U.toggle(fp, "t_steal", "t_steal_d", "autoSteal", function() syncFarm() end, toggles)
    U.toggle(fp, "t_return", "t_return_d", "autoReturn", function() syncFarm() end, toggles)
    U.toggle(fp, "t_hatch", "t_hatch_d", "autoHatch", function() syncFarm() end, toggles)

    U.section(fp, "s_anti", C.success)
    local info = mk("Frame", {
        Parent = fp, BackgroundColor3 = C.card_alt,
        Size = UDim2.new(1, 0, 0, 110), BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = info, CornerRadius = UDim.new(0, 12) })
    mk("TextLabel", {
        Parent = info, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -30, 0, 18),
        Font = Enum.Font.GothamBold, Text = "🛡 ANTI-CHEAT ACTIVE",
        TextColor3 = C.primary_d, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9004,
    })
    mk("TextLabel", {
        Parent = info, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 32), Size = UDim2.new(1, -30, 1, -44),
        Font = Enum.Font.Gotham,
        Text = "· Human delay 0.08-0.35s\n· Tween move (no teleport)\n· Burst: 4-6 eggs, then rest 8-16s\n· Speed cap: 26\n· Randomized targets",
        TextColor3 = C.text_mut, TextSize = 10, TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9004,
    })

    -- ESP
    local ep = pages.esp
    U.section(ep, "s_esp", C.violet)
    U.toggle(ep, "t_esp_egg", "t_esp_egg_d", "espEgg", nil, toggles)
    U.toggle(ep, "t_esp_player", "t_esp_player_d", "espPlayer", nil, toggles)
    U.toggle(ep, "t_esp_base", "t_esp_base_d", "espBase", nil, toggles)

    -- PLAYER
    local pl = pages.player
    U.section(pl, "s_safety", C.success)
    U.toggle(pl, "t_afk", "t_afk_d", "antiAfk", nil, toggles)
    U.toggle(pl, "t_noclip", "t_noclip_d", "noclip", nil, toggles)

    -- CONFIG
    local cp = pages.config
    U.section(cp, "s_ui", C.primary)
    U.toggle(cp, "t_notif", nil, "notifications", nil, toggles)
    U.toggle(cp, "t_sound", nil, "clickSound", nil, toggles)

    U.section(cp, "s_lang", C.accent)
    local langRow = mk("Frame", {
        Parent = cp, BackgroundColor3 = C.white,
        Size = UDim2.new(1, 0, 0, 68), BorderSizePixel = 0, ZIndex = 9002,
    })
    mk("UICorner", { Parent = langRow, CornerRadius = UDim.new(0, 14) })
    mk("UIStroke", { Parent = langRow, Color = C.border, Thickness = 1 })
    local prevB = mk("TextButton", {
        Parent = langRow, BackgroundColor3 = C.card_alt,
        Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.new(0, 44, 0, 44),
        AnchorPoint = Vector2.new(0, 0.5), Text = "◀",
        TextColor3 = C.text, TextSize = 18, Font = Enum.Font.GothamBold,
        AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = prevB, CornerRadius = UDim.new(0, 10) })
    local langDisp = mk("TextLabel", {
        Parent = langRow, BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
        AnchorPoint = Vector2.new(0.5, 0), Font = Enum.Font.GothamBold,
        Text = "", TextColor3 = C.text, TextSize = 14, ZIndex = 9003,
    })
    local nxtB = mk("TextButton", {
        Parent = langRow, BackgroundColor3 = C.card_alt,
        Position = UDim2.new(1, -58, 0.5, 0), Size = UDim2.new(0, 44, 0, 44),
        AnchorPoint = Vector2.new(0, 0.5), Text = "▶",
        TextColor3 = C.text, TextSize = 18, Font = Enum.Font.GothamBold,
        AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = nxtB, CornerRadius = UDim.new(0, 10) })

    local function updLangDisp()
        for _, L in ipairs(LANGS) do
            if L.code == CurLang then langDisp.Text = L.flag .. "  " .. L.name; return end
        end
    end
    updLangDisp()

    local function chLang(dir)
        local idx = 1
        for i, L in ipairs(LANGS) do if L.code == CurLang then idx = i; break end end
        idx = idx + dir
        if idx < 1 then idx = #LANGS end
        if idx > #LANGS then idx = 1 end
        CurLang = LANGS[idx].code
        saveLang(CurLang)
        updFlag(); updLangDisp()
        if rebuildRef.fn then rebuildRef.fn() end
        notif:push(t("s_lang"), t("m_lang") .. ": " .. LANGS[idx].name, "success", 2)
    end
    prevB.Activated:Connect(function() chLang(-1) end)
    nxtB.Activated:Connect(function() chLang(1) end)

    U.section(cp, "s_profile", C.success)
    U.button(cp, "btn_save", "success", function()
        local data = {}
        for k, v in pairs(S) do
            if type(v) == "boolean" or type(v) == "number" then data[k] = v end
        end
        if writefile then
            pcall(writefile, "sv_egg_config.json", HttpService:JSONEncode(data))
            notif:push(t("s_profile"), t("m_saved"), "success", 2)
        end
    end)
    U.button(cp, "btn_load", "ghost", function()
        if readfile and isfile and isfile("sv_egg_config.json") then
            local ok, d = pcall(function() return HttpService:JSONDecode(readfile("sv_egg_config.json")) end)
            if ok and d then
                for k, v in pairs(d) do
                    if S[k] ~= nil and type(S[k]) == type(v) then
                        S[k] = v
                        if toggles[k] then toggles[k](v, true) end
                    end
                end

                syncFarm()

                notif:push(t("s_profile"), t("m_loaded"), "success", 2)
            else
                notif:push(t("s_profile"), "Invalid save data", "error", 2)
            end
        else
            notif:push(t("s_profile"), "No save data", "warn", 2)
        end
    end)
    U.button(cp, "btn_reset", "danger", function()
        if writefile then pcall(writefile, "sv_egg_config.json", "{}") end
        notif:push(t("s_profile"), t("m_reset"), "warn", 2)
    end)

    U.section(cp, "s_keys", C.warn)
    local kb = mk("Frame", {
        Parent = cp, BackgroundColor3 = C.card_alt,
        Size = UDim2.new(1, 0, 0, 90), BorderSizePixel = 0, ZIndex = 9002,
    })
    mk("UICorner", { Parent = kb, CornerRadius = UDim.new(0, 14) })
    local kbLbl = mk("TextLabel", {
        Parent = kb, BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 14), Size = UDim2.new(1, -36, 1, -28),
        Font = Enum.Font.Code, TextColor3 = C.text_soft, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = t("kb_txt"), ZIndex = 9003,
    })
    kbLbl:SetAttribute("i18n", "kb_txt")

    -- DEBUG
    local dbp = pages.debug
    U.section(dbp, "s_debug", C.accent)
    local logFrame = mk("Frame", {
        Parent = dbp, BackgroundColor3 = C.bg_deep,
        Size = UDim2.new(1, 0, 0, 320), BorderSizePixel = 0, ZIndex = 9002,
    })
    mk("UICorner", { Parent = logFrame, CornerRadius = UDim.new(0, 14) })
    local logScroll = mk("ScrollingFrame", {
        Parent = logFrame, BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 12), Size = UDim2.new(1, -24, 1, -24),
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.border_h,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 9003,
    })
    mk("UIListLayout", { Parent = logScroll, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder })

    local function refreshLog()
        for _, c in ipairs(logScroll:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        if #DLog == 0 then
            local e = mk("TextLabel", {
                Parent = logScroll, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.Code,
                Text = t("dbg_empty"), TextColor3 = C.text_dim, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9004,
            })
            e:SetAttribute("i18n", "dbg_empty")
            return
        end
        for i = #DLog, math.max(1, #DLog - 40), -1 do
            local e = DLog[i]
            local col = C.text
            if e.kind == "success" then col = C.success
            elseif e.kind == "error" then col = C.danger
            elseif e.kind == "warn" then col = C.warn end
            mk("TextLabel", {
                Parent = logScroll, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Code,
                Text = "› " .. e.msg, TextColor3 = col, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9004,
            })
        end
    end
    refreshLog()
    task.spawn(function()
        while logFrame.Parent do
            task.wait(2); refreshLog()
        end
    end)
    U.button(dbp, "btn_clear", "danger", function()
        DLog = {}; refreshLog()
    end)

    -- FOOTER
    local ft = mk("Frame", {
        Parent = panel, BackgroundColor3 = C.bg_deep,
        Position = UDim2.new(0, 0, 1, -40), Size = UDim2.new(1, 0, 0, 40),
        BorderSizePixel = 0, ZIndex = 9002, ClipsDescendants = true,
    })
    mk("UICorner", { Parent = ft, CornerRadius = UDim.new(0, 22) })
    mk("Frame", {
        Parent = ft, BackgroundColor3 = C.bg_deep,
        Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0.5, 0),
        BorderSizePixel = 0, ZIndex = 9002,
    })
    mk("Frame", {
        Parent = ft, BackgroundColor3 = C.border,
        Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0, ZIndex = 9003,
    })
    local dotF = mk("Frame", {
        Parent = ft, BackgroundColor3 = C.danger,
        Position = UDim2.new(0, 20, 0.5, 0), Size = UDim2.new(0, 10, 0, 10),
        AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, ZIndex = 9003,
    })
    mk("UICorner", { Parent = dotF, CornerRadius = UDim.new(1, 0) })
    local statusLbl = mk("TextLabel", {
        Parent = ft, BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold, Text = t("idle"),
        TextColor3 = C.text_mut, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9003,
    })
    statusLbl:SetAttribute("i18n", "idle")
    local fpsLbl = mk("TextLabel", {
        Parent = ft, BackgroundTransparency = 1,
        Position = UDim2.new(1, -140, 0, 0), Size = UDim2.new(0, 128, 1, 0),
        Font = Enum.Font.GothamBold, Text = "FPS --  Ping --",
        TextColor3 = C.text_dim, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 9003,
    })

    Farm.onStatus = function(running)
        tw(dotF, 0.2, { BackgroundColor3 = running and C.success or C.danger })
        statusLbl.Text = running and t("run") or t("idle")
        statusLbl.TextColor3 = running and C.success or C.text_mut
        subInfo.Text = running and ("● " .. t("run")) or ("● " .. t("idle"))
        subInfo.TextColor3 = running and C.success or C.text_mut
    end

    task.spawn(function()
        local f, t0 = 0, tick()
        RunService.RenderStepped:Connect(function()
            f = f + 1
            if tick() - t0 >= 1 then
                local fps = f / (tick() - t0)
                local ping = "?"
                pcall(function()
                    ping = math.floor(StatsSvc.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                fpsLbl.Text = string.format("FPS %d  Ping %s", math.floor(fps), ping)
                f, t0 = 0, tick()
            end
        end)
    end)

    -- Drag
    local dg, ds, sp_ = false, nil, nil
    topBar.InputBegan:Connect(function(i)
        if isClick(i) then dg = true; ds = i.Position; sp_ = panel.Position end
    end)
    topBar.InputEnded:Connect(function(i) if isClick(i) then dg = false end end)
    UIS.InputChanged:Connect(function(i)
        if dg and isMove(i) then
            local d = i.Position - ds
            panel.Position = UDim2.new(0, sp_.X.Offset + d.X, 0.5, sp_.Y.Offset + d.Y)
        end
    end)

    closeBtn.MouseEnter:Connect(function() tw(closeBtn, 0.15, { BackgroundColor3 = C.danger }) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, 0.15, { BackgroundColor3 = C.danger_l }) end)
    langBtn.MouseEnter:Connect(function() tw(langBtn, 0.15, { BackgroundColor3 = C.primary_l }) end)
    langBtn.MouseLeave:Connect(function() tw(langBtn, 0.15, { BackgroundColor3 = C.sky }) end)

    closeBtn.Activated:Connect(function()
        tw(panel, 0.25, { Position = UDim2.new(0, -panel.AbsoluteSize.X, 0.5, panel.Position.Y.Offset) })
        task.wait(0.25)
        panel.Visible = false
        if hiddenRef.fn then hiddenRef.fn(false) end
    end)

    switchTab("dash", 1)

    -- Language overlay
    local langOverlay = mk("Frame", {
        Parent = panel, BackgroundColor3 = C.bg,
        Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 9100,
    })
    mk("UICorner", { Parent = langOverlay, CornerRadius = UDim.new(0, 22) })
    local lh = mk("Frame", {
        Parent = langOverlay, BackgroundColor3 = C.white,
        Size = UDim2.new(1, 0, 0, 64), BorderSizePixel = 0, ZIndex = 9101,
    })
    mk("UICorner", { Parent = lh, CornerRadius = UDim.new(0, 22) })
    mk("Frame", {
        Parent = lh, BackgroundColor3 = C.white,
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0.5, 0),
        BorderSizePixel = 0, ZIndex = 9101,
    })
    mk("TextLabel", {
        Parent = lh, BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -80, 1, 0),
        Font = Enum.Font.GothamBold, Text = t("s_lang"):upper(),
        TextColor3 = C.text, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9102,
    })
    local langClose = mk("TextButton", {
        Parent = lh, BackgroundColor3 = C.danger_l,
        Position = UDim2.new(1, -54, 0.5, 0), Size = UDim2.new(0, 36, 0, 36),
        AnchorPoint = Vector2.new(0, 0.5), Text = "✕", TextColor3 = C.danger,
        TextSize = 16, Font = Enum.Font.GothamBold, AutoButtonColor = false,
        BorderSizePixel = 0, ZIndex = 9102,
    })
    mk("UICorner", { Parent = langClose, CornerRadius = UDim.new(0, 10) })
    local ll = mk("ScrollingFrame", {
        Parent = langOverlay, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 78), Size = UDim2.new(1, -32, 1, -94),
        BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.border_h, ZIndex = 9101,
    })
    mk("UIListLayout", { Parent = ll, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    for _, L in ipairs(LANGS) do
        local row = mk("TextButton", {
            Parent = ll,
            BackgroundColor3 = (L.code == CurLang) and C.primary or C.white,
            Size = UDim2.new(1, 0, 0, 56), Text = "", AutoButtonColor = false,
            BorderSizePixel = 0, ZIndex = 9102,
        })
        mk("UICorner", { Parent = row, CornerRadius = UDim.new(0, 12) })
        mk("UIStroke", { Parent = row, Color = C.border, Thickness = 1, Transparency = 0.5 })
        mk("TextLabel", {
            Parent = row, BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0, 44, 1, 0),
            Font = Enum.Font.GothamBold, Text = L.flag,
            TextColor3 = C.white, TextSize = 26,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9103,
        })
        mk("TextLabel", {
            Parent = row, BackgroundTransparency = 1,
            Position = UDim2.new(0, 66, 0, 0), Size = UDim2.new(1, -100, 1, 0),
            Font = Enum.Font.GothamBold, Text = L.name,
            TextColor3 = (L.code == CurLang) and C.white or C.text,
            TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9103,
        })
        row.Activated:Connect(function()
            CurLang = L.code
            saveLang(L.code)
            updFlag(); updLangDisp()
            if rebuildRef.fn then rebuildRef.fn() end
            langOverlay.Visible = false
            notif:push(t("s_lang"), t("m_lang") .. ": " .. L.name, "success", 2)
        end)
    end
    langBtn.Activated:Connect(function() langOverlay.Visible = true end)
    langClose.Activated:Connect(function() langOverlay.Visible = false end)

    rebuildRef.fn = function()
        for _, d in ipairs(panel:GetDescendants()) do
            local key = d:GetAttribute("i18n")
            if key and (d:IsA("TextLabel") or d:IsA("TextButton")) then
                d.Text = t(key)
            end
        end
        statusLbl.Text = Farm.running and t("run") or t("idle")
        updFlag(); updLangDisp()
    end

    return panel
end

-- ═══════════════════════════════════════════════════════════════
-- FLOATING BUTTON
-- ═══════════════════════════════════════════════════════════════
local function buildButton(parent, onTap)
    local btn = mk("TextButton", {
        Parent = parent, BackgroundColor3 = C.white, BorderSizePixel = 0,
        Position = S.btnPos, Size = UDim2.new(0, 84, 0, 84), Text = "",
        AutoButtonColor = false, Active = true, Selectable = false, ZIndex = 9500,
    })
    mk("UICorner", { Parent = btn, CornerRadius = UDim.new(1, 0) })

    local sh = mk("Frame", {
        Parent = parent, BackgroundColor3 = C.shadow,
        BackgroundTransparency = 0.88, BorderSizePixel = 0,
        Position = S.btnPos, Size = UDim2.new(0, 84, 0, 84), ZIndex = 9499,
    })
    mk("UICorner", { Parent = sh, CornerRadius = UDim.new(1, 0) })
    sh.Position = btn.Position
    btn:GetPropertyChangedSignal("Position"):Connect(function() sh.Position = btn.Position end)

    mk("UIGradient", { Parent = btn, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.white),
        ColorSequenceKeypoint.new(1, C.sky),
    }), Rotation = 45 })

    local stroke = mk("UIStroke", { Parent = btn, Color = C.primary, Thickness = 2, Transparency = 0.15 })

    local ring = mk("Frame", {
        Parent = btn, BackgroundTransparency = 1,
        Size = UDim2.new(1, 6, 1, 6), Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 9501,
    })
    mk("UICorner", { Parent = ring, CornerRadius = UDim.new(1, 0) })
    local rs = mk("UIStroke", { Parent = ring, Color = C.primary, Thickness = 2, Transparency = 0.7 })
    task.spawn(function()
        while btn.Parent do
            if btn.Active then
                rs.Transparency = 0.7
                tw(ring, 1.2, { Size = UDim2.new(1, 26, 1, 26) })
                tw(rs, 1.2, { Transparency = 1 })
                task.wait(1.2)
                ring.Size = UDim2.new(1, 6, 1, 6)
                rs.Transparency = 0.7
            end
            task.wait(0.05)
        end
    end)

    local logoHolder = mk("Frame", {
        Parent = btn, BackgroundTransparency = 1,
        Size = UDim2.new(0, 46, 0, 46), Position = UDim2.new(0.5, 0, 0, 8),
        AnchorPoint = Vector2.new(0.5, 0), ZIndex = 9502,
    })
    drawSVLogo(logoHolder, 46)

    local stateLbl = mk("TextLabel", {
        Parent = btn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold, Text = "SV",
        TextColor3 = C.primary_d, TextSize = 9, ZIndex = 9503,
    })

    local function save(p)
        if writefile then
            pcall(writefile, "sv_egg_pos.json",
                HttpService:JSONEncode({ x = p.X.Scale, xo = p.X.Offset, y = p.Y.Scale, yo = p.Y.Offset }))
        end
    end
    local function load()
        if readfile and isfile and isfile("sv_egg_pos.json") then
            local ok, d = pcall(function() return HttpService:JSONDecode(readfile("sv_egg_pos.json")) end)
            if ok and d then btn.Position = UDim2.new(d.x, d.xo, d.y, d.yo) end
        end
    end
    load()

    local drag, dst, sst, moved = false, nil, nil, false
    btn.InputBegan:Connect(function(i)
        if isClick(i) then
            drag = true; moved = false; dst = i.Position; sst = btn.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag or not isMove(i) then return end
        local d = i.Position - dst
        if d.Magnitude > CFG.DRAG_PX then moved = true end
        if moved then
            btn.Position = UDim2.new(sst.X.Scale, sst.X.Offset + d.X, sst.Y.Scale, sst.Y.Offset + d.Y)
        end
    end)
    local function finish()
        if not drag then return end
        drag = false
        if moved then save(btn.Position) end
        task.delay(0.2, function() moved = false end)
    end
    btn.InputEnded:Connect(function(i) if isClick(i) then finish() end end)
    UIS.InputEnded:Connect(function(i) if isClick(i) then finish() end end)

    local lastTap = 0
    local function doTap()
        if moved then return end
        local now = tick()
        if now - lastTap < CFG.TAP then return end
        lastTap = now
        task.spawn(function() safe(onTap) end)
    end
    btn.Activated:Connect(doTap)
    btn.MouseButton1Click:Connect(doTap)
    pcall(function() btn.TouchTap:Connect(doTap) end)

    local function setActive(active)
        if active then
            tw(btn, 0.18, { BackgroundColor3 = C.success_l })
            stroke.Color = C.success
            rs.Color = C.success
            stateLbl.Text = "STEAL"
            stateLbl.TextColor3 = C.success_d
        else
            tw(btn, 0.18, { BackgroundColor3 = C.white })
            stroke.Color = C.primary
            rs.Color = C.primary
            stateLbl.Text = "SV"
            stateLbl.TextColor3 = C.primary_d
        end
    end
    local function setHidden(h)
        tw(btn, 0.2, { BackgroundTransparency = h and 1 or 0 })
        tw(sh, 0.2, { BackgroundTransparency = h and 1 or 0.88 })
        btn.Active = not h
    end
    return btn, setActive, setHidden
end

-- ═══════════════════════════════════════════════════════════════
-- LOADING SCREEN
-- ═══════════════════════════════════════════════════════════════
local function showLoading(screen, onDone)
    local ov = mk("Frame", {
        Parent = screen, BackgroundColor3 = C.bg,
        Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 99999,
    })
    local gF = mk("Frame", {
        Parent = ov, BackgroundColor3 = C.white, BackgroundTransparency = 0.4,
        Size = UDim2.new(2, 0, 2, 0), Position = UDim2.new(-0.5, 0, -0.5, 0),
        BorderSizePixel = 0, ZIndex = 99999,
    })
    mk("UIGradient", { Parent = gF, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.sky),
        ColorSequenceKeypoint.new(0.5, C.white),
        ColorSequenceKeypoint.new(1, C.primary_xl),
    }), Rotation = 45 })

    -- Particles
    for i = 1, 8 do
        local p = mk("Frame", {
            Parent = ov, BackgroundColor3 = C.primary,
            BackgroundTransparency = 0.7,
            Size = UDim2.new(0, math.random(6, 12), 0, math.random(6, 12)),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            BorderSizePixel = 0, ZIndex = 99999,
        })
        mk("UICorner", { Parent = p, CornerRadius = UDim.new(1, 0) })
        task.spawn(function()
            while p.Parent do
                local dur = 3 + math.random() * 4
                pcall(function()
                    tw(p, dur, { Position = UDim2.new(math.random(), 0, math.random(), 0) }, Enum.EasingStyle.Sine)
                end)
                task.wait(dur)
            end
        end)
    end

    local c = mk("Frame", {
        Parent = ov, BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 0, 240),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 100000,
    })

    local logoHolder = mk("Frame", {
        Parent = c, BackgroundTransparency = 1,
        Size = UDim2.new(0, 88, 0, 88),
        Position = UDim2.new(0.5, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0), ZIndex = 100001,
    })
    drawSVLogo(logoHolder, 88)

    mk("TextLabel", {
        Parent = c, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 102), Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.GothamBold, Text = "ScriptVault",
        TextColor3 = C.text, TextSize = 26, ZIndex = 100001,
    })
    mk("TextLabel", {
        Parent = c, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 136), Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamMedium,
        Text = "Steal an Egg · AAA v" .. CFG.VER,
        TextColor3 = C.text_mut, TextSize = 12, ZIndex = 100001,
    })

    local bBg = mk("Frame", {
        Parent = c, BackgroundColor3 = C.card_alt,
        Position = UDim2.new(0.1, 0, 0, 180), Size = UDim2.new(0.8, 0, 0, 8),
        BorderSizePixel = 0, ZIndex = 100001,
    })
    mk("UICorner", { Parent = bBg, CornerRadius = UDim.new(1, 0) })
    local fill = mk("Frame", {
        Parent = bBg, BackgroundColor3 = C.primary,
        Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, ZIndex = 100002,
    })
    mk("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })
    mk("UIGradient", { Parent = fill, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.primary),
        ColorSequenceKeypoint.new(1, C.accent),
    }) })

    local statLbl = mk("TextLabel", {
        Parent = c, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 200), Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamMedium, Text = t("loading"),
        TextColor3 = C.text_soft, TextSize = 11, ZIndex = 100001,
    })

    local finished = false
    local function finish()
        if finished then return end
        finished = true
        if ov and ov.Parent then
            tw(ov, 0.35, { BackgroundTransparency = 1 })
            task.wait(0.4)
            pcall(function() ov:Destroy() end)
        end
        if onDone then safe(onDone) end
    end

    task.spawn(function()
        tw(fill, 0.3, { Size = UDim2.new(0.5, 0, 1, 0) }, Enum.EasingStyle.Quint)
        statLbl.Text = t("load_modules")
        task.wait(0.35)
        tw(fill, 0.3, { Size = UDim2.new(0.85, 0, 1, 0) }, Enum.EasingStyle.Quint)
        statLbl.Text = t("load_gui")
        task.wait(0.35)
        tw(fill, 0.3, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Quint)
        statLbl.Text = t("load_ready")
        task.wait(0.35)
        finish()
    end)

    task.delay(2.5, finish)
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN
-- ═══════════════════════════════════════════════════════════════
local notif = Notif.new(SCREEN)
local panel = buildPanel(SCREEN, notif)
LOG("Panel built:", panel ~= nil)

if not panel then
    LOG("FATAL: panel nil")
    return
end

local btn, setActive, setHidden = buildButton(SCREEN, function()
    panel.Visible = not panel.Visible
    if panel.Visible then
        setHidden(true)
        panel.Position = UDim2.new(0, -panel.AbsoluteSize.X, 0.5, 0)
        twIn(panel, 0.32, { Position = UDim2.new(0, 26, 0.5, 0) })
    else
        setHidden(false)
    end
    local on = Farm:toggle()
    setActive(on)
    notif:push(t("s_master"), on and t("m_on") or t("m_off"),
        on and "success" or "warn", 2)
end)
LOG("Button built:", btn ~= nil)

if not btn then
    LOG("FATAL: button nil")
    return
end

hiddenRef.fn = setHidden

-- Keybinds
UIS.InputBegan:Connect(function(input, processed)
    if not isCurrentRuntime() or processed then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        panel.Visible = not panel.Visible
        setHidden(panel.Visible)
        if panel.Visible then
            panel.Position = UDim2.new(0, -panel.AbsoluteSize.X, 0.5, 0)
            twIn(panel, 0.32, { Position = UDim2.new(0, 26, 0.5, 0) })
        end
    elseif input.KeyCode == Enum.KeyCode.F2 then
        setActive(Farm:toggle())
    elseif input.KeyCode == Enum.KeyCode.F3 then
        local eggs = findEggs()
        if #eggs > 0 then stealOne(eggs[1]) end
    elseif input.KeyCode == Enum.KeyCode.F4 then
        returnHome()
    elseif input.KeyCode == Enum.KeyCode.F5 then
        S.noclip = not S.noclip
        if toggles["noclip"] then toggles["noclip"](S.noclip, true) end
    elseif input.KeyCode == Enum.KeyCode.F6 then
        S.espEgg = not S.espEgg
        if toggles["espEgg"] then toggles["espEgg"](S.espEgg, true) end
    end
end)

pcall(function()
    if game.BindToClose then
        game:BindToClose(function()
            pcall(function() Farm:stop() end)
        end)
    end
end)

showLoading(SCREEN, function()
    pcall(findMyBase)
    pcall(findRemotes)
    if notif then
        notif:push(t("welcome") .. ", " .. LP.DisplayName .. "!",
            t("loaded"), "success", 4)
    end
    if Refs.myBase then
        LOG("Base found:", Refs.myBase.Name)
    else
        notif:push(t("m_nobase"), t("m_nobase_tip"), "warn", 4)
    end
    LOG("═══════════════════════════════════════")
    LOG("SCRIPT FULLY LOADED")
    LOG("Look for SV button (left side)")
    LOG("Parent:", GUI_PARENT_NAME)
    LOG("═══════════════════════════════════════")
end)

LOG("Bootstrap complete")
