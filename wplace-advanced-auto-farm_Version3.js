// ==UserScript==
// @name         Wplace Advanced Auto Farm
// @namespace    https://github.com/Eduardo854832/Wplace-Script
// @version      2.0
// @description  Script avançado para automatização de pintura no wplace.live com múltiplos idiomas e recursos extras
// @author       Eduardo854832
// @match        https://wplace.live/*
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_addStyle
// @run-at       document-idle
// ==/UserScript==

(function() {
    'use strict';
    
    // Namespace para evitar conflitos
    const WplaceAutoFarm = {
        // Configurações padrão
        config: {
            language: 'pt', // 'en' ou 'pt'
            interval: 5000, // Intervalo entre pixels em ms
            autoDetectCooldown: true, // Detectar cooldown automaticamente
            currentPattern: 'farm', // Padrão atual
            startX: 0,
            startY: 0,
            showStats: true, // Mostrar estatísticas
            autoRestart: true, // Reiniciar automaticamente ao concluir
            nightMode: false, // Modo noturno para interface
            soundEffects: true // Efeitos sonoros
        },
        
        // Estado atual
        state: {
            isRunning: false,
            farmProcess: null,
            currentX: 0,
            currentY: 0,
            pixelsPlaced: 0,
            startTime: null,
            lastPlaced: null,
            canvasSize: 10, // Tamanho do pixel (será atualizado)
            errors: 0
        },
        
        // Traduções
        translations: {
            en: {
                title: 'Advanced Auto Farm',
                status: {
                    waiting: 'Waiting',
                    running: 'Running',
                    error: 'Error',
                    cooldown: 'Cooldown',
                    stopped: 'Stopped'
                },
                buttons: {
                    start: 'Start',
                    stop: 'Stop',
                    setPosition: 'Set Position',
                    settings: 'Settings',
                    close: 'Close',
                    save: 'Save',
                    reset: 'Reset'
                },
                labels: {
                    startPosition: 'Start Position:',
                    currentPos: 'Current: ',
                    nextPixel: 'Next: ',
                    speed: 'Speed:',
                    pattern: 'Pattern:',
                    language: 'Language:',
                    placedPixels: 'Pixels Placed: ',
                    runtime: 'Runtime: ',
                    pixelsPerMin: 'Pixels/min: ',
                    autoDetect: 'Auto-detect cooldown',
                    autoRestart: 'Auto-restart after completion',
                    nightMode: 'Night mode',
                    soundEffects: 'Sound effects',
                    showStats: 'Show statistics'
                },
                patterns: {
                    farm: 'Farm (Soil & Crops)',
                    garden: 'Garden (Flowers)',
                    fishpond: 'Fish Pond',
                    custom: 'Custom Pattern'
                },
                messages: {
                    setPosFirst: 'Set initial position first!',
                    pixelPlaced: 'Pixel placed at',
                    patternComplete: 'Pattern completed!',
                    waitingCooldown: 'Waiting for cooldown',
                    settingsSaved: 'Settings saved',
                    startFromCanvas: 'Click on canvas to set starting point'
                },
                speedLabels: {
                    verySlow: 'Very Slow (10s)',
                    slow: 'Slow (5s)',
                    medium: 'Medium (3s)',
                    fast: 'Fast (1s)',
                    veryFast: 'Very Fast (0.5s)',
                    custom: 'Custom'
                }
            },
            pt: {
                title: 'Auto Farm Avançado',
                status: {
                    waiting: 'Aguardando',
                    running: 'Em execução',
                    error: 'Erro',
                    cooldown: 'Aguardando cooldown',
                    stopped: 'Parado'
                },
                buttons: {
                    start: 'Iniciar',
                    stop: 'Parar',
                    setPosition: 'Definir Posição',
                    settings: 'Configurações',
                    close: 'Fechar',
                    save: 'Salvar',
                    reset: 'Redefinir'
                },
                labels: {
                    startPosition: 'Posição inicial:',
                    currentPos: 'Atual: ',
                    nextPixel: 'Próximo: ',
                    speed: 'Velocidade:',
                    pattern: 'Padrão:',
                    language: 'Idioma:',
                    placedPixels: 'Pixels colocados: ',
                    runtime: 'Tempo de execução: ',
                    pixelsPerMin: 'Pixels/min: ',
                    autoDetect: 'Detectar cooldown automaticamente',
                    autoRestart: 'Reiniciar após completar',
                    nightMode: 'Modo noturno',
                    soundEffects: 'Efeitos sonoros',
                    showStats: 'Mostrar estatísticas'
                },
                patterns: {
                    farm: 'Fazenda (Solo e Plantações)',
                    garden: 'Jardim (Flores)',
                    fishpond: 'Lago de Peixes',
                    custom: 'Padrão Personalizado'
                },
                messages: {
                    setPosFirst: 'Defina a posição inicial primeiro!',
                    pixelPlaced: 'Pixel colocado em',
                    patternComplete: 'Padrão completado!',
                    waitingCooldown: 'Aguardando cooldown',
                    settingsSaved: 'Configurações salvas',
                    startFromCanvas: 'Clique no canvas para definir ponto inicial'
                },
                speedLabels: {
                    verySlow: 'Muito Lento (10s)',
                    slow: 'Lento (5s)',
                    medium: 'Médio (3s)',
                    fast: 'Rápido (1s)',
                    veryFast: 'Muito Rápido (0.5s)',
                    custom: 'Personalizado'
                }
            }
        },
        
        // Padrões pré-definidos
        patterns: {
            farm: {
                colors: {
                    S: 6, // Solo (marrom)
                    C: 2, // Plantação (verde)
                    W: 3, // Água (azul)
                    F: 5  // Cerca (cinza)
                },
                layout: [
                    "FFFFFFFFFF",
                    "FSSSSSSSF",
                    "FSCSCSCSF",
                    "FSSSSSSSF",
                    "FSCSCSCSF",
                    "FSSSSSSSF",
                    "FWWWWWWWF",
                    "FFFFFFFFFF"
                ]
            },
            garden: {
                colors: {
                    G: 2,  // Grama (verde claro)
                    R: 11, // Rosa (rosa)
                    Y: 7,  // Margarida (amarelo)
                    B: 4,  // Mirtilo (azul escuro)
                    P: 9,  // Lavanda (roxo)
                    W: 3   // Caminho de água (azul)
                },
                layout: [
                    "GGGGGGGGG",
                    "GRYGBYPYG",
                    "GGGWWWGGG",
                    "GPYRBYRYG",
                    "GGGWWWGGG",
                    "GYRBPBRYG",
                    "GGGGGGGGG"
                ]
            },
            fishpond: {
                colors: {
                    G: 2,  // Grama (verde)
                    S: 6,  // Areia (bege)
                    W: 3,  // Água rasa (azul claro)
                    D: 4,  // Água profunda (azul escuro)
                    F: 8   // Peixe (laranja)
                },
                layout: [
                    "GGGGGGGGG",
                    "GSSSSSSG",
                    "GSWWWWSG",
                    "GSWDDFSG",
                    "GSWDWWSG",
                    "GSWWWWSG",
                    "GSSSSSSG",
                    "GGGGGGGGG"
                ]
            },
            custom: {
                colors: {
                    // Será preenchido pelo usuário
                    X: 0,
                    Y: 1,
                    Z: 2
                },
                layout: [
                    "XXXXXX",
                    "XYYYYX",
                    "XYZZZX",
                    "XXXXXX"
                ]
            }
        },
        
        // Elementos da UI
        ui: {
            controlPanel: null,
            settingsPanel: null,
            statusElement: null,
            btnToggle: null
        },
        
        // Sons
        sounds: {
            place: new Audio("data:audio/mp3;base64,SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA//tQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAASAAAeMwAUFBQUFBQUFBQkJCQkJCQkJCQ0NDQ0NDQ0NDRERERERERERERUVFRUVFRUVFRkZGRkZGRkZGR0dHR0dHR0dHSEhISEhISEhISUlJSUlJSUlJSkpKSkpKSkpKS0tLS0tLS0tLS0xMTExMTExMTU1NTU1NTU1NTk5OTk5OTk5OT09PT09PT09PT///8AAAAATGF2YzU4LjEzAAAAAAAAAAAAAAAAJAX/LDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/7kGQAAANUMEoFPeACNQYJQJ5kAIAAAaQAAAAgAAA0gAAABP///////////////5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N//7kmRAP/DTDdGBPHACNKGJ/CeNAAMMMMoE8yAIz4YnIJ4kA5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N//7kGRAP/DTDdGBPHACM6GJ/CeNAAMsMM4E8cAIzYYnQJ40A5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N//7kmRAP/DTDdGBPGACNOGJ0CeNAAK0MUuE8YAI0IYnQJ4wA5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N//7kmRAP/DTDdGBPGACNOGJ0CeNAAMkMUwE8YAIzYYnQJ4wA5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N5JFW8N1N"),
            error: new Audio("data:audio/mp3;base64,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
        },
        
        // Métodos principais
        initialize: function() {
            console.log('WplaceAutoFarm: Inicializando...');
            
            // Carregar configurações salvas
            this.loadSettings();
            
            // Aguardar o carregamento completo da página e do canvas
            this.waitForCanvas().then(() => {
                this.createInterface();
                this.setupEventListeners();
                this.applyTheme();
                
                // Iniciar com mensagem de status
                this.updateStatus(this.t('status.waiting'));
            }).catch(error => {
                console.error('Erro ao inicializar o script:', error);
            });
        },
        
        // Carregar configurações salvas
        loadSettings: function() {
            try {
                const savedConfig = GM_getValue('wplaceAutoFarmConfig');
                if (savedConfig) {
                    this.config = {...this.config, ...JSON.parse(savedConfig)};
                }
            } catch (error) {
                console.error('Erro ao carregar configurações:', error);
            }
        },
        
        // Salvar configurações
        saveSettings: function() {
            try {
                GM_setValue('wplaceAutoFarmConfig', JSON.stringify(this.config));
            } catch (error) {
                console.error('Erro ao salvar configurações:', error);
            }
        },
        
        // Aguardar o carregamento do canvas do wplace
        waitForCanvas: function() {
            return new Promise((resolve, reject) => {
                const maxAttempts = 30;
                let attempts = 0;
                
                const checkCanvas = () => {
                    // Ajuste este seletor conforme o site wplace.live
                    const canvas = document.querySelector('canvas');
                    
                    if (canvas) {
                        // Detectar tamanho do pixel no canvas
                        this.detectCanvasSettings(canvas);
                        resolve(canvas);
                    } else if (attempts >= maxAttempts) {
                        reject(new Error('Canvas não encontrado após várias tentativas'));
                    } else {
                        attempts++;
                        setTimeout(checkCanvas, 1000);
                    }
                };
                
                checkCanvas();
            });
        },
        
        // Detectar configurações do canvas
        detectCanvasSettings: function(canvas) {
            // Detectar tamanho do pixel
            // Isso é um placeholder - você precisará adaptar de acordo com wplace.live
            const canvasWidth = canvas.width;
            const gridSize = 100; // Supondo que o grid seja 100x100
            this.state.canvasSize = canvasWidth / gridSize;
        },
        
        // Criar interface de usuário
        createInterface: function() {
            this.createControlPanel();
            this.createSettingsPanel();
            
            // Aplicar tema
            this.applyTheme();
        },
        
        // Criar painel de controle
        createControlPanel: function() {
            // Adicionar estilos CSS
            GM_addStyle(`
                .waf-panel {
                    position: fixed;
                    bottom: 20px;
                    right: 20px;
                    background-color: rgba(40, 44, 52, 0.9);
                    color: white;
                    border-radius: 15px;
                    padding: 15px;
                    z-index: 10000;
                    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5);
                    font-family: Arial, sans-serif;
                    max-width: 300px;
                    min-width: 220px;
                    touch-action: none;
                    user-select: none;
                    transition: background-color 0.3s ease;
                }
                
                .waf-night-mode {
                    background-color: rgba(20, 22, 26, 0.95);
                }
                
                .waf-title {
                    margin-bottom: 10px;
                    font-weight: bold;
                    font-size: 16px;
                    text-align: center;
                    position: relative;
                }
                
                .waf-status {
                    font-size: 12px;
                    color: #4caf50;
                    text-align: center;
                    margin-top: 5px;
                }
                
                .waf-input-group {
                    margin-bottom: 15px;
                }
                
                .waf-input-label {
                    margin-bottom: 5px;
                    display: block;
                }
                
                .waf-input-row {
                    display: flex;
                    justify-content: space-between;
                }
                
                .waf-input {
                    width: 40%;
                    padding: 8px;
                    border-radius: 5px;
                    border: none;
                    background-color: rgba(255, 255, 255, 0.1);
                    color: white;
                    text-align: center;
                }
                
                .waf-button {
                    background-color: #4caf50;
                    border: none;
                    color: white;
                    padding: 10px;
                    border-radius: 5px;
                    font-weight: bold;
                    cursor: pointer;
                    transition: background-color 0.2s ease;
                }
                
                .waf-button:hover {
                    background-color: #3e8e41;
                }
                
                .waf-button-row {
                    display: flex;
                    justify-content: space-between;
                }
                
                .waf-button-start {
                    background-color: #2196f3;
                }
                
                .waf-button-start:hover {
                    background-color: #0b7dda;
                }
                
                .waf-button-stop {
                    background-color: #f44336;
                }
                
                .waf-button-stop:hover {
                    background-color: #d32f2f;
                }
                
                .waf-button-settings {
                    background-color: #ff9800;
                    width: 100%;
                    margin-top: 10px;
                }
                
                .waf-button-settings:hover {
                    background-color: #e68a00;
                }
                
                .waf-info {
                    margin-top: 10px;
                    font-size: 12px;
                    text-align: center;
                }
                
                .waf-info-item {
                    margin: 2px 0;
                }
                
                .waf-drag-handle {
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    height: 10px;
                    cursor: move;
                    background-color: rgba(255, 255, 255, 0.1);
                    border-radius: 15px 15px 0 0;
                }
                
                .waf-stats {
                    border-top: 1px solid rgba(255, 255, 255, 0.1);
                    margin-top: 10px;
                    padding-top: 10px;
                    font-size: 11px;
                    display: flex;
                    flex-direction: column;
                    gap: 3px;
                }
                
                /* Settings Panel */
                .waf-settings-panel {
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    background-color: rgba(40, 44, 52, 0.95);
                    color: white;
                    border-radius: 15px;
                    padding: 20px;
                    z-index: 10001;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.7);
                    font-family: Arial, sans-serif;
                    max-width: 90%;
                    width: 300px;
                    display: none;
                }
                
                .waf-settings-title {
                    text-align: center;
                    font-size: 18px;
                    font-weight: bold;
                    margin-bottom: 15px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
                    padding-bottom: 10px;
                }
                
                .waf-settings-group {
                    margin-bottom: 15px;
                }
                
                .waf-settings-label {
                    display: block;
                    margin-bottom: 5px;
                }
                
                .waf-select {
                    width: 100%;
                    padding: 8px;
                    background-color: rgba(255, 255, 255, 0.1);
                    color: white;
                    border: none;
                    border-radius: 5px;
                    margin-bottom: 10px;
                }
                
                .waf-checkbox-label {
                    display: flex;
                    align-items: center;
                    margin-bottom: 8px;
                    cursor: pointer;
                }
                
                .waf-checkbox {
                    margin-right: 8px;
                }
                
                .waf-buttons-footer {
                    display: flex;
                    justify-content: space-between;
                    margin-top: 15px;
                }
                
                .waf-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background-color: rgba(0, 0, 0, 0.5);
                    z-index: 10000;
                    display: none;
                }
            `);
            
            // Criar painel de controle
            const panel = document.createElement('div');
            panel.className = 'waf-panel';
            
            // Conteúdo HTML do painel
            panel.innerHTML = `
                <div class="waf-title">
                    ${this.t('title')}
                    <div class="waf-drag-handle"></div>
                </div>
                <div class="waf-status" id="waf-status">${this.t('status.waiting')}</div>
                
                <div class="waf-input-group">
                    <div class="waf-input-label">${this.t('labels.startPosition')}</div>
                    <div class="waf-input-row">
                        <input type="number" id="waf-start-x" class="waf-input" placeholder="X" value="${this.config.startX}">
                        <input type="number" id="waf-start-y" class="waf-input" placeholder="Y" value="${this.config.startY}">
                    </div>
                </div>
                
                <div class="waf-button-row">
                    <button id="waf-btn-set-pos" class="waf-button" style="width: 48%;">${this.t('buttons.setPosition')}</button>
                    <button id="waf-btn-toggle" class="waf-button waf-button-start" style="width: 48%;">${this.t('buttons.start')}</button>
                </div>
                
                <button id="waf-btn-settings" class="waf-button waf-button-settings">${this.t('buttons.settings')}</button>
                
                <div class="waf-info">
                    <div id="waf-current-pos" class="waf-info-item">${this.t('labels.currentPos')}-</div>
                    <div id="waf-next-pixel" class="waf-info-item">${this.t('labels.nextPixel')}-</div>
                </div>
            `;
            
            // Adicionar estatísticas se habilitado
            if (this.config.showStats) {
                panel.innerHTML += `
                    <div class="waf-stats">
                        <div id="waf-pixels-placed">${this.t('labels.placedPixels')}0</div>
                        <div id="waf-runtime">${this.t('labels.runtime')}00:00:00</div>
                        <div id="waf-pixels-per-min">${this.t('labels.pixelsPerMin')}0</div>
                    </div>
                `;
            }
            
            document.body.appendChild(panel);
            this.ui.controlPanel = panel;
            this.ui.statusElement = document.getElementById('waf-status');
            this.ui.btnToggle = document.getElementById('waf-btn-toggle');
            
            // Tornar o painel arrastável
            this.makeDraggable(panel, panel.querySelector('.waf-drag-handle'));
        },
        
        // Criar painel de configurações
        createSettingsPanel: function() {
            const overlay = document.createElement('div');
            overlay.className = 'waf-overlay';
            document.body.appendChild(overlay);
            
            const panel = document.createElement('div');
            panel.className = 'waf-settings-panel';
            
            // Conteúdo HTML do painel de configurações
            panel.innerHTML = `
                <div class="waf-settings-title">${this.t('buttons.settings')}</div>
                
                <div class="waf-settings-group">
                    <label class="waf-settings-label">${this.t('labels.speed')}</label>
                    <select id="waf-speed" class="waf-select">
                        <option value="10000">${this.t('speedLabels.verySlow')}</option>
                        <option value="5000">${this.t('speedLabels.slow')}</option>
                        <option value="3000">${this.t('speedLabels.medium')}</option>
                        <option value="1000">${this.t('speedLabels.fast')}</option>
                        <option value="500">${this.t('speedLabels.veryFast')}</option>
                        <option value="custom">${this.t('speedLabels.custom')}</option>
                    </select>
                    <input type="number" id="waf-custom-speed" class="waf-input" placeholder="ms" style="width: 100%; display: none;" min="100" max="60000">
                </div>
                
                <div class="waf-settings-group">
                    <label class="waf-settings-label">${this.t('labels.pattern')}</label>
                    <select id="waf-pattern" class="waf-select">
                        <option value="farm">${this.t('patterns.farm')}</option>
                        <option value="garden">${this.t('patterns.garden')}</option>
                        <option value="fishpond">${this.t('patterns.fishpond')}</option>
                        <option value="custom">${this.t('patterns.custom')}</option>
                    </select>
                </div>
                
                <div class="waf-settings-group">
                    <label class="waf-settings-label">${this.t('labels.language')}</label>
                    <select id="waf-language" class="waf-select">
                        <option value="pt">Português</option>
                        <option value="en">English</option>
                    </select>
                </div>
                
                <div class="waf-settings-group">
                    <label class="waf-checkbox-label">
                        <input type="checkbox" id="waf-auto-cooldown" class="waf-checkbox" ${this.config.autoDetectCooldown ? 'checked' : ''}>
                        ${this.t('labels.autoDetect')}
                    </label>
                    
                    <label class="waf-checkbox-label">
                        <input type="checkbox" id="waf-auto-restart" class="waf-checkbox" ${this.config.autoRestart ? 'checked' : ''}>
                        ${this.t('labels.autoRestart')}
                    </label>
                    
                    <label class="waf-checkbox-label">
                        <input type="checkbox" id="waf-night-mode" class="waf-checkbox" ${this.config.nightMode ? 'checked' : ''}>
                        ${this.t('labels.nightMode')}
                    </label>
                    
                    <label class="waf-checkbox-label">
                        <input type="checkbox" id="waf-sound-effects" class="waf-checkbox" ${this.config.soundEffects ? 'checked' : ''}>
                        ${this.t('labels.soundEffects')}
                    </label>
                    
                    <label class="waf-checkbox-label">
                        <input type="checkbox" id="waf-show-stats" class="waf-checkbox" ${this.config.showStats ? 'checked' : ''}>
                        ${this.t('labels.showStats')}
                    </label>
                </div>
                
                <div class="waf-buttons-footer">
                    <button id="waf-btn-save" class="waf-button" style="width: 48%;">${this.t('buttons.save')}</button>
                    <button id="waf-btn-close" class="waf-button" style="width: 48%;">${this.t('buttons.close')}</button>
                