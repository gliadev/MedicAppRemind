<div align="center">

<img src="docs/screenshots/icon.png" alt="MediRemind" width="120" height="120" />

# MediRemind

**Tus medicinas, sin olvidos.**

App iOS para gestionar medicación: control de stock, cálculo de pastillas y días restantes,
recordatorios de toma y avisos de recarga. Diseñada con la accesibilidad como requisito clínico
para pacientes crónicos y personas mayores.

![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)
![Platform](https://img.shields.io/badge/iOS%20%7C%20iPadOS-26%2B-000000?logo=apple&logoColor=white)
![UI](https://img.shields.io/badge/SwiftUI-Liquid%20Glass-2C6ED6)
![Persistence](https://img.shields.io/badge/SwiftData%20%2B%20CloudKit-1F8A5F)
![Accessibility](https://img.shields.io/badge/WCAG%202.2-AA-1F8A5F)
![Dependencies](https://img.shields.io/badge/dependencias-0-informational)

</div>

---

## 📸 Capturas

> Las imágenes de esta sección son **placeholders**. Sustituye cada archivo en
> `docs/screenshots/` por la captura real (mismo nombre) y se actualizan solas —
> no hace falta tocar este README.

| Hoy | Medicamentos | Detalle |
|:---:|:---:|:---:|
| <img src="docs/screenshots/01-hoy.png" width="230" /> | <img src="docs/screenshots/02-lista.png" width="230" /> | <img src="docs/screenshots/03-detalle.png" width="230" /> |
| Tomas del día y progreso | Stock ok / bajo / crítico | Pastillas, días y pauta |

| Recordatorio | Accesibilidad (Dynamic Type AX5) |
|:---:|:---:|
| <img src="docs/screenshots/04-recordatorio.png" width="230" /> | <img src="docs/screenshots/05-accesibilidad.png" width="230" /> |
| Notificación con acciones rápidas | Texto grande + alto contraste |

---

## ✨ Características

- **Control de stock** — pastillas restantes, días de suministro y aviso antes de quedarte sin existencias.
- **Recordatorios de toma** — notificaciones locales puntuales, con acciones rápidas desde la propia notificación.
- **Vista "Hoy"** — todas las tomas del día y tu progreso de un vistazo.
- **Cálculo de dosis** — `remainingDays = stock / (pastillas por toma × tomas al día)` y fecha de recarga estimada.
- **Sincronización privada** — entre tus dispositivos con iCloud (CloudKit), sin servidor propio.
- **Siri y Atajos** — registra una toma o consulta tu stock por voz (App Intents).
- **Calendario** — espeja tus tomas como eventos con EventKit, si quieres.
- **Español e inglés** — localización completa (ES source + EN).

---

## ♿️ Accesibilidad primero

La accesibilidad no es un acabado, es un requisito clínico. Cada pantalla pasa una auditoría
**WCAG 2.2 nivel AA** antes de darse por terminada:

- Contraste ≥ 4.5:1 (texto) / 3:1 (componentes UI) en claro **y** oscuro.
- **Dynamic Type** exclusivamente; layout sin romperse hasta AX5.
- Ningún estado se comunica solo por color (color **+** icono **+** texto).
- Touch targets ≥ 44×44 pt; botones con icono siempre con label textual.
- VoiceOver navegable; `reduceMotion` y `reduceTransparency` respetados.

---

## 🏗️ Arquitectura y stack

100% frameworks de Apple, **cero dependencias externas**.

```
Domain (value types) → SwiftData @Model → @Query / View
                     ↘ Services (Notifications, Calendar, Intents)
```

| Área | Tecnología |
|---|---|
| Lenguaje | Swift 6.2 — modo estricto, `StrictConcurrency = complete`, Approachable Concurrency |
| UI | SwiftUI exclusivamente, Liquid Glass (iOS 26) |
| Persistencia | SwiftData como Single Source of Truth local |
| Sincronización | CloudKit (contenedor privado, `NSPersistentCloudKitContainer`) |
| Notificaciones | UserNotifications (recordatorios de toma + bajo stock) |
| Calendario | EventKit |
| Siri / Atajos | App Intents + `AppShortcutsProvider` |
| Red | `URLSession` + `async/await` + `Codable` |
| Tests | Swift Testing (`@Test`, `#expect`, `#require`) |

**Principios:** dominio puro y testeable para los cálculos clínicos, `@Query` solo dentro de vistas,
escrituras vía `@ModelActor`, schema CloudKit-safe desde el diseño, cero warnings (tratados como error),
strings en String Catalog (nada hardcodeado).

---

## 📂 Estructura del repositorio

```
MedicAppRemind/            # Código de la app, organizado por feature
MedicAppRemindTests/       # Tests unitarios (Swift Testing)
MedicAppRemind.xcodeproj/  # Proyecto Xcode
MedicAppRemind.xctestplan  # Plan de tests
ci_scripts/                # Scripts de Xcode Cloud
docs/screenshots/          # Capturas del README
```

---

## 🔒 Privacidad

Privacidad por diseño: tus datos viven en tu dispositivo y en tu iCloud privado.
Sin servidor propio, sin analítica, sin terceros. No se recopilan ni se venden datos.

> MediRemind no sustituye el consejo de un profesional sanitario.

---

## 🚀 Build

Proyecto: `MedicAppRemind-iOS/MedicAppRemind/MedicAppRemind.xcodeproj`.
Requiere Xcode 26+ y iOS/iPadOS 26+. Build y tests desde Xcode (`Cmd+B` / `Cmd+U`).

---

## 📄 Licencia

_Pendiente de definir._

---

<div align="center">

Hecho con 💙 para quien no puede permitirse olvidar una toma.

**gliadev** · gliatem@gmail.com

</div>
