# Publicar Run For Win en Google Play

Lista de lo que hace falta, en el orden en que conviene hacerlo. Datos
verificados en julio de 2026; las fechas y los umbrales de Google cambian, así
que confirma en la documentación oficial antes de dar algo por hecho.

## El camino crítico: 12 testers durante 14 días

Esto es lo que más tarda y casi nadie lo tiene en cuenta al planificar.

Las **cuentas personales creadas después del 13 de noviembre de 2023** tienen
que ejecutar una **prueba cerrada con al menos 12 testers dados de alta durante
14 días consecutivos** antes de poder solicitar acceso a producción. Las cuentas
de organización están exentas.

- «Dado de alta» significa que el tester aceptó la invitación **e instaló la app**
  con esa misma cuenta de Google. Un correo invitado que no instala no cuenta.
- El contador de 14 días arranca cuando Google aprueba la release *y* hay 12
  testers dentro. Si un tester se sale, el contador se resiente.
- Después hay que solicitar acceso a producción: la revisión suele tardar unos 7
  días.

**Presupuesta entre 3 y 4 semanas** desde que empiezas hasta que puedes publicar.
Consigue los 12 testers antes de nada.

## Requisitos técnicos con fecha

| Qué | Cuándo | Estado |
|---|---|---|
| API objetivo **36** (Android 16) para apps nuevas | desde el 31 de agosto de 2026 | ⚠️ hay que apuntar ahí desde el principio |
| Compatibilidad con **páginas de 16 KB** | ya obligatorio para apps nuevas | verificar |
| Formato **AAB** (Android App Bundle), no APK | ya | — |

Como el proceso de testers dura más de un mes, apunta a **API 36** desde la
primera build y te ahorras rehacerlo a mitad.

Sobre las páginas de 16 KB: Flutter es compatible salvo que haya módulos nativos
propios que hagan mapeo de memoria. Este proyecto no los tiene, pero usa
`audioplayers`, `hive` y `in_app_purchase`, que sí traen código nativo — mantén
Flutter y los plugins en versiones recientes y compruébalo en una build real.

## 1. Proyecto nativo

Hoy el repositorio **no tiene carpeta `android/`**: el juego se ha desarrollado y
desplegado solo para web.

```bash
flutter create --platforms=android,ios .
```

Dos decisiones **irreversibles** tras publicar:

- **`applicationId`.** `com.example.run_for_win` lo rechaza Google. Y el
  identificador no se puede cambiar nunca después. Propuesta:
  `art.ironcoding.runforwin`.
- **Keystore.** Si se pierde, no hay más actualizaciones. Activa Play App
  Signing y guarda keystore y contraseña en dos sitios distintos.

Además: iconos de lanzador, `versionCode` / `versionName` (hoy `1.0.0+1` en
`pubspec.yaml`) y revisar que el nombre visible de la app sea «Run For Win» y no
el codename interno `BrixRun`.

## 2. Cuenta de desarrollador

- 25 USD, pago único.
- Verificación de identidad: nombre, dirección y teléfono. Las cuentas de
  organización necesitan además un **D-U-N-S**; las personales no.
- **Guarda el ID de transacción de ese pago.** Lo pide el proceso de
  transferencia si algún día la app pasa a una cuenta de empresa, y es de las
  cosas que la gente borra del correo.

## 3. Ficha de la tienda

Todo el material redactado está en
[iron-coding.art/proyectos/run-for-win/prensa.html](https://iron-coding.art/proyectos/run-for-win/prensa.html).

| Elemento | Requisito |
|---|---|
| Título | 30 caracteres |
| Descripción corta | 80 caracteres |
| Descripción completa | 4000 caracteres |
| Icono | 512 × 512 px |
| Gráfico destacado | 1024 × 500 px |
| Capturas de teléfono | mínimo 2, hasta 8 |

## 4. Formularios de la consola

- **Clasificación de contenido** (cuestionario IARC).
- **Público objetivo y contenido.** Si se declara que incluye menores, la app
  entra en la política de Familias. Este juego cumple sus requisitos por diseño
  —sin anuncios, sin SDK de terceros, analítica local, sin cajas de botín— pero
  la decisión hay que tomarla a conciencia porque hay una suscripción de por
  medio (ver `COMPRAS_REALES.md`).
- **Seguridad de los datos.** Tiene que coincidir **exactamente** con la
  política de privacidad publicada. Lo que aplica aquí:
  - Progreso y preferencias: se guardan solo en el dispositivo.
  - Analítica: propia, local, sin envío a terceros.
  - Compras: las procesa la tienda; nosotros no vemos datos de pago.
- **Anuncios:** el juego no tiene. Declararlo.
- **Acceso a la app:** no requiere cuenta; declararlo para que el revisor no
  pida credenciales.

## 5. Enlaces obligatorios

| Qué | URL |
|---|---|
| Política de privacidad | `https://iron-coding.art/proyectos/run-for-win/privacidad.html` |
| Soporte | `https://iron-coding.art/proyectos/run-for-win/soporte.html` |
| Términos | `https://iron-coding.art/proyectos/run-for-win/terminos.html` |

Google Play exige un **correo de soporte** que funcione. La App Store exige una
**URL de soporte funcional** y sin ella no se puede ni enviar a revisión: un
placeholder o un «próximamente» es motivo de rechazo.

⚠️ **`soporte@iron-coding.art` tiene que existir y responder antes de enviar.**

## 6. Antes de subir

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Comprueba también que la demo web sigue compilando, porque comparte el código:

```bash
flutter build web --release --base-href "/lego-custom-character/"
```

## Orden recomendado

1. Generar el proyecto nativo con el `applicationId` definitivo y API 36.
2. Crear el buzón `soporte@iron-coding.art`.
3. Abrir la cuenta de Play y subir una primera build a prueba interna.
4. Dar de alta los productos de compra (necesita release subida y perfil de
   pagos verificado).
5. Arrancar la prueba cerrada con 12 testers — **el camino crítico**.
6. Mientras corren los 14 días: rellenar la ficha, los formularios y probar las
   compras con cuentas de prueba de licencia.
7. Solicitar acceso a producción.

## Referencias

- [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Target API level requirements for Google Play apps](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Support 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes)
- [Transfer apps to a different developer account](https://support.google.com/googleplay/android-developer/answer/6230247)
