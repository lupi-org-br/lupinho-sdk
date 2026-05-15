# lupi-sdk

Ambiente de desenvolvimento para jogos Lupi. Monitora a pasta `src/`, processa os assets, compila o jogo para WebAssembly e serve na porta 3000 — tudo automaticamente a cada vez que você salva um arquivo.

## Pré-requisitos

- Docker

## Uso

### 1. Build da imagem (apenas uma vez, ou após alterar o Dockerfile)

```bash
make build
```

### 2. Iniciar o servidor de desenvolvimento

```bash
make run
```

O terminal mostrará os logs ao vivo. Quando aparecer:

```
[lupi] Done! Recarregue o browser para ver as alteracoes.
```

Abra ou recarregue o browser em:

```
http://localhost:3000/webgame/game.html
```

## Estrutura do projeto

```
lupi-sdk/
├── src/          ← seus arquivos de jogo (Lua + assets)
│   ├── game.lua  ← ponto de entrada do jogo
│   ├── palette.lua
│   └── player/
│       └── f1.png, f2.png ...
├── dist/         ← saída gerada (não edite manualmente)
├── Dockerfile
└── Makefile
```

## Fluxo de build

Toda vez que um arquivo em `src/` é salvo, o pipeline roda automaticamente:

1. **Codec** — processa os assets (converte PNGs para BGR555, gera manifesto)
2. **Zip** — empacota o release em `jogo.lupi`
3. **Emscripten** — compila o engine Lupinho com o jogo embutido para WebAssembly
4. **Cópia** — move os arquivos para `dist/webgame/`

Se uma nova alteração chegar enquanto o build está rodando, o build atual é cancelado e um novo começa com o estado mais recente dos arquivos.

## Tipos de asset suportados

| Tipo | Extensão | Resultado |
|------|----------|-----------|
| Sprites | `.png` | Convertido para bitmap BGR555 |
| Código Lua | `.lua` | Copiado sem alteração |
| Mapas Tiled | `.json` | Convertido para script Lua |

Restrições de imagem: máximo 512×512px e até 256 cores.

## API do jogo

O arquivo `game.lua` deve definir uma função `update()` chamada a cada frame.

```lua
require("sprites")
require("palette")

function update()
    -- desenha sprite
    ui.spr(Sprites.player["f1"], x, y)

    -- texto
    ui.print("texto", x, y, cor)

    -- formas
    ui.rect(x1, y1, x2, y2, cor)
    ui.circfill(cx, cy, raio, cor)
    ui.trisfill(x1, y1, x2, y2, x3, y3, cor)

    -- input
    if ui.btnp(BTN_Z) then ... end
end
```

### Animação de sprites

```lua
frame = 1
frame_timer = 0
FRAME_SPEED = 8  -- ticks por frame de animação

function update()
    frame_timer = frame_timer + 1
    if frame_timer >= FRAME_SPEED then
        frame_timer = 0
        frame = frame + 1
        if frame > 6 then frame = 1 end
    end
    ui.spr(Sprites.player["f" .. frame], x, y)
end
```
