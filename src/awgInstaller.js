import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';
import { logger } from './logger.js';

const execAsync = promisify(exec);

// Конфигурация контейнеров
const CONTAINERS = {
    v1: {
        name: 'amnezia-awg',
        configPath: '/opt/amnezia/amnezia-awg',
        image: 'amneziavpn/amnezia-wg:latest',
        network: '10.8.1.0/24',
        params: {
            Jc: 6,
            Jmin: 10,
            Jmax: 50,
            S1: 90,
            S2: 52,
            H1: 547255503,
            H2: 446059580,
            H3: 1955843234,
            H4: 1872536766
        }
    },
    v2: {
        name: 'amnezia-awg2',
        configPath: '/opt/amnezia/amnezia-awg2',
        image: 'amneziavpn/amnezia-wg:latest',
        network: '10.8.1.0/24',
        params: {
            Jc: 6,
            Jmin: 10,
            Jmax: 50,
            S1: 103,
            S2: 79,
            S3: 31,
            S4: 9,
            H1: '1726271876-1813116022',
            H2: '1831845225-2080655774',
            H3: '2099907137-2143693563',
            H4: '2146332087-2147440200'
        }
    }
};

/**
 * Проверка установленных серверов
 * @returns {Promise<Object>} Статус установленных серверов
 */
async function checkInstalledServers() {
    logger.info('[AWGInstaller] Проверка установленных серверов...');
    
    const status = {
        v1: await getServerInfo('v1'),
        v2: await getServerInfo('v2')
    };
    
    logger.info(`[AWGInstaller] v1: ${status.v1.installed ? 'установлен' : 'не установлен'}`);
    logger.info(`[AWGInstaller] v2: ${status.v2.installed ? 'установлен' : 'не установлен'}`);
    
    return status;
}

/**
 * Получение информации о сервере
 * @param {string} version - Версия сервера (v1 или v2)
 * @returns {Promise<Object>} Информация о сервере
 */
async function getServerInfo(version) {
    const container = CONTAINERS[version];
    
    try {
        // Проверяем существование контейнера
        const { stdout } = await execAsync(`docker ps -a --filter name=^${container.name}$ --format "{{.Status}}"`);
        
        if (!stdout.trim()) {
            return {
                installed: false,
                containerName: container.name,
                port: null,
                clientCount: 0,
                configPath: null,
                status: 'not_found'
            };
        }
        
        const isRunning = stdout.includes('Up');
        
        // Получаем порт
        let port = null;
        try {
            const { stdout: portOutput } = await execAsync(`docker port ${container.name} 2>/dev/null || true`);
            const portMatch = portOutput.match(/0\.0\.0\.0:(\d+)/);
            if (portMatch) {
                port = parseInt(portMatch[1]);
            }
        } catch (error) {
            logger.warn(`[AWGInstaller] Не удалось получить порт для ${container.name}`);
        }
        
        // Подсчитываем клиентов
        const clientCount = await countClients(container.name);
        
        return {
            installed: true,
            containerName: container.name,
            port,
            clientCount,
            configPath: container.configPath,
            status: isRunning ? 'running' : 'stopped'
        };
    } catch (error) {
        logger.error(`[AWGInstaller] Ошибка получения информации о ${version}: ${error.message}`);
        return {
            installed: false,
            containerName: container.name,
            port: null,
            clientCount: 0,
            configPath: null,
            status: 'error'
        };
    }
}

/**
 * Подсчёт клиентов в конфигурации
 * @param {string} containerName - Имя контейнера
 * @returns {Promise<number>} Количество клиентов
 */
async function countClients(containerName) {
    try {
        const { stdout } = await execAsync(`docker exec ${containerName} grep -c "\\[Peer\\]" /opt/amnezia/awg/wg0.conf 2>/dev/null || echo "0"`);
        return parseInt(stdout.trim()) || 0;
    } catch (error) {
        logger.warn(`[AWGInstaller] Не удалось подсчитать клиентов для ${containerName}`);
        return 0;
    }
}

/**
 * Удаление сервера
 * @param {string} version - Версия сервера (v1 или v2)
 * @returns {Promise<boolean>} Успешность удаления
 */
async function removeServer(version) {
    const container = CONTAINERS[version];
    logger.info(`[AWGInstaller] Удаление сервера ${version}...`);
    
    try {
        // Останавливаем контейнер
        try {
            await execAsync(`docker stop ${container.name}`);
            logger.info(`[AWGInstaller] Контейнер ${container.name} остановлен`);
        } catch (error) {
            logger.warn(`[AWGInstaller] Контейнер ${container.name} уже остановлен или не существует`);
        }
        
        // Удаляем контейнер
        try {
            await execAsync(`docker rm ${container.name}`);
            logger.info(`[AWGInstaller] Контейнер ${container.name} удалён`);
        } catch (error) {
            logger.warn(`[AWGInstaller] Контейнер ${container.name} не найден`);
        }
        
        // Удаляем конфигурационные файлы
        try {
            await execAsync(`rm -rf ${container.configPath}`);
            logger.info(`[AWGInstaller] Конфигурация ${container.configPath} удалена`);
        } catch (error) {
            logger.warn(`[AWGInstaller] Не удалось удалить конфигурацию: ${error.message}`);
        }
        
        return true;
    } catch (error) {
        logger.error(`[AWGInstaller] Ошибка удаления сервера ${version}: ${error.message}`);
        return false;
    }
}

/**
 * Проверка наличия wireguard-tools на хосте
 * @returns {Promise<boolean>} true если установлен
 */
async function checkWireguardTools() {
    const methods = [
        'nsenter -t 1 -m -u -i -n /usr/bin/which wg',
        'nsenter -t 1 -m -u -i -n which wg',
        'nsenter -t 1 -m sh -c "which wg"'
    ];
    
    for (const method of methods) {
        try {
            await execAsync(method);
            logger.info('[AWGInstaller] wireguard-tools найден на хосте');
            return true;
        } catch (error) {
            continue;
        }
    }
    
    return false;
}

/**
 * Установка wireguard-tools с несколькими методами fallback
 * @returns {Promise<void>}
 */
async function installWireguardTools() {
    logger.warn('[AWGInstaller] wireguard-tools не найден, устанавливаю...');
    
    const methods = [
        // Метод 1: Полные пути с nsenter
        {
            name: 'Full paths with nsenter',
            commands: [
                'nsenter -t 1 -m -u -i -n /usr/bin/apt-get update -qq',
                'nsenter -t 1 -m -u -i -n /usr/bin/apt-get install -y -qq wireguard-tools'
            ]
        },
        // Метод 2: nsenter с sh -c
        {
            name: 'nsenter with sh -c',
            commands: [
                'nsenter -t 1 -m -u -i -n sh -c "apt-get update -qq"',
                'nsenter -t 1 -m -u -i -n sh -c "apt-get install -y -qq wireguard-tools"'
            ]
        },
        // Метод 3: nsenter с chroot
        {
            name: 'nsenter with chroot',
            commands: [
                'nsenter -t 1 -m chroot /proc/1/root /usr/bin/apt-get update -qq',
                'nsenter -t 1 -m chroot /proc/1/root /usr/bin/apt-get install -y -qq wireguard-tools'
            ]
        }
    ];
    
    for (const method of methods) {
        try {
            logger.info(`[AWGInstaller] Попытка установки: ${method.name}`);
            for (const cmd of method.commands) {
                await execAsync(cmd);
            }
            logger.info(`[AWGInstaller] wireguard-tools успешно установлен методом: ${method.name}`);
            return;
        } catch (error) {
            logger.warn(`[AWGInstaller] Метод ${method.name} не сработал: ${error.message}`);
            continue;
        }
    }
    
    throw new Error('Не удалось установить wireguard-tools ни одним из методов');
}

/**
 * Генерация серверных ключей на хосте через nsenter
 * wireguard-tools должен быть установлен через install.sh
 * @returns {Promise<Object>} Объект с ключами
 */
async function generateServerKeys() {
    logger.info('[AWGInstaller] Генерация ключей сервера на хосте...');
    
    try {
        // Проверяем наличие wireguard-tools на хосте
        const hasWg = await checkWireguardTools();
        
        if (!hasWg) {
            await installWireguardTools();
        }
        
        // Генерируем ключи с fallback методами
        const keyMethods = [
            'nsenter -t 1 -m -u -i -n /usr/bin/wg genkey',
            'nsenter -t 1 -m -u -i -n wg genkey',
            'nsenter -t 1 -m sh -c "wg genkey"'
        ];
        
        let privateKey = '';
        for (const method of keyMethods) {
            try {
                const { stdout } = await execAsync(method);
                privateKey = stdout.trim();
                break;
            } catch (error) {
                continue;
            }
        }
        
        if (!privateKey) {
            throw new Error('Не удалось сгенерировать приватный ключ');
        }
        
        // Генерируем публичный ключ из приватного
        const pubKeyMethods = [
            `echo "${privateKey}" | nsenter -t 1 -m -u -i -n /usr/bin/wg pubkey`,
            `echo "${privateKey}" | nsenter -t 1 -m -u -i -n wg pubkey`,
            `echo "${privateKey}" | nsenter -t 1 -m sh -c "wg pubkey"`
        ];
        
        let publicKey = '';
        for (const method of pubKeyMethods) {
            try {
                const { stdout } = await execAsync(method);
                publicKey = stdout.trim();
                break;
            } catch (error) {
                continue;
            }
        }
        
        if (!publicKey) {
            throw new Error('Не удалось сгенерировать публичный ключ');
        }
        
        // Генерируем PresharedKey
        const pskMethods = [
            'nsenter -t 1 -m -u -i -n /usr/bin/wg genpsk',
            'nsenter -t 1 -m -u -i -n wg genpsk',
            'nsenter -t 1 -m sh -c "wg genpsk"'
        ];
        
        let presharedKey = '';
        for (const method of pskMethods) {
            try {
                const { stdout } = await execAsync(method);
                presharedKey = stdout.trim();
                break;
            } catch (error) {
                continue;
            }
        }
        
        if (!presharedKey) {
            throw new Error('Не удалось сгенерировать preshared ключ');
        }
        
        const keys = {
            privateKey,
            publicKey,
            presharedKey
        };
        
        logger.info('[AWGInstaller] Ключи успешно сгенерированы на хосте');
        return keys;
    } catch (error) {
        logger.error(`[AWGInstaller] Ошибка генерации ключей: ${error.message}`);
        throw new Error(`Не удалось сгенерировать ключи. Ошибка: ${error.message}`);
    }
}

/**
 * Создание конфигурации сервера
 * @param {string} version - Версия сервера (v1 или v2)
 * @param {number} port - Порт сервера
 * @param {Object} keys - Ключи сервера
 * @param {string} configPath - Путь к конфигурации
 * @returns {Promise<void>}
 */
async function createServerConfig(version, port, keys, configPath) {
    logger.info(`[AWGInstaller] Создание конфигурации для ${version}...`);
    
    const container = CONTAINERS[version];
    const params = container.params;
    
    // Формируем конфигурацию в зависимости от версии
    let config = `[Interface]
PrivateKey = ${keys.privateKey}
Address = ${container.network}
ListenPort = ${port}
Jc = ${params.Jc}
Jmin = ${params.Jmin}
Jmax = ${params.Jmax}
S1 = ${params.S1}
S2 = ${params.S2}
`;

    // Для v2 добавляем дополнительные параметры
    if (version === 'v2') {
        config += `S3 = ${params.S3}
S4 = ${params.S4}
`;
    }
    
    // Добавляем H-параметры
    config += `H1 = ${params.H1}
H2 = ${params.H2}
H3 = ${params.H3}
H4 = ${params.H4}
`;

    try {
        // Создаём директорию
        await execAsync(`mkdir -p ${configPath}`);
        
        // Записываем конфигурацию
        await fs.writeFile(`${configPath}/wg0.conf`, config);
        logger.info(`[AWGInstaller] Конфиг записан: ${configPath}/wg0.conf`);
        
        // Записываем ключи
        await fs.writeFile(`${configPath}/wireguard_server_private_key.key`, keys.privateKey);
        await fs.writeFile(`${configPath}/wireguard_server_public_key.key`, keys.publicKey);
        await fs.writeFile(`${configPath}/wireguard_psk.key`, keys.presharedKey);
        
        logger.info('[AWGInstaller] Конфигурация успешно создана');
    } catch (error) {
        logger.error(`[AWGInstaller] Ошибка создания конфигурации: ${error.message}`);
        throw new Error(`Не удалось создать конфигурацию: ${error.message}`);
    }
}

/**
 * Запуск Docker контейнера
 * @param {string} version - Версия сервера (v1 или v2)
 * @param {number} port - Порт сервера
 * @param {string} configPath - Путь к конфигурации
 * @returns {Promise<void>}
 */
async function startContainer(version, port, configPath) {
    const container = CONTAINERS[version];
    logger.info(`[AWGInstaller] Запуск контейнера ${container.name}...`);
    
    const dockerCmd = `docker run -d \
  --name ${container.name} \
  --restart=always \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -p ${port}:${port}/udp \
  -v ${configPath}:/opt/amnezia/awg \
  -v /lib/modules:/lib/modules:ro \
  ${container.image}`;
    
    try {
        await execAsync(dockerCmd);
        logger.info(`[AWGInstaller] Контейнер ${container.name} успешно запущен`);
        
        // Ждём 2 секунды для инициализации
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Проверяем статус
        const { stdout } = await execAsync(`docker ps --filter name=^${container.name}$ --format "{{.Status}}"`);
        if (!stdout.includes('Up')) {
            throw new Error('Контейнер не запустился');
        }
        
        logger.info(`[AWGInstaller] Контейнер ${container.name} работает`);
    } catch (error) {
        logger.error(`[AWGInstaller] Ошибка запуска контейнера: ${error.message}`);
        throw new Error(`Не удалось запустить контейнер: ${error.message}`);
    }
}

/**
 * Установка сервера
 * @param {string} version - Версия сервера (v1 или v2)
 * @param {number} port - Порт сервера
 * @param {Function} progressCallback - Callback для обновления прогресса
 * @returns {Promise<Object>} Результат установки
 */
async function installServer(version, port, progressCallback = () => {}) {
    const container = CONTAINERS[version];
    const configPath = container.configPath;
    
    logger.info(`[AWGInstaller] Начало установки ${version} на порту ${port}`);
    
    try {
        // Шаг 1: Создание директорий
        progressCallback('⏳ Создаю директории...');
        await execAsync(`mkdir -p ${configPath}`);
        logger.info(`[AWGInstaller] Директория ${configPath} создана`);
        
        // Шаг 2: Генерация ключей
        progressCallback('⏳ Генерирую ключи сервера...');
        const keys = await generateServerKeys();
        
        // Шаг 3: Создание конфигурации
        progressCallback('⏳ Создаю конфигурацию...');
        await createServerConfig(version, port, keys, configPath);
        
        // Шаг 4: Скачивание образа
        progressCallback('⏳ Скачиваю образ Docker...');
        await execAsync(`docker pull ${container.image}`);
        logger.info(`[AWGInstaller] Образ ${container.image} скачан`);
        
        // Шаг 5: Запуск контейнера
        progressCallback('⏳ Запускаю контейнер...');
        await startContainer(version, port, configPath);
        
        progressCallback('✅ Установка завершена!');
        
        logger.info(`[AWGInstaller] Установка ${version} успешно завершена`);
        
        return {
            success: true,
            containerName: container.name,
            port,
            configPath,
            publicKey: keys.publicKey,
            presharedKey: keys.presharedKey
        };
    } catch (error) {
        logger.error(`[AWGInstaller] Ошибка установки ${version}: ${error.message}`);
        
        // Пытаемся откатить изменения
        try {
            await removeServer(version);
        } catch (rollbackError) {
            logger.error(`[AWGInstaller] Ошибка отката: ${rollbackError.message}`);
        }
        
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * Установка обоих серверов
 * @param {number} portV1 - Порт для v1
 * @param {number} portV2 - Порт для v2
 * @param {Function} progressCallback - Callback для обновления прогресса
 * @returns {Promise<Object>} Результат установки
 */
async function installBothServers(portV1, portV2, progressCallback = () => {}) {
    logger.info(`[AWGInstaller] Установка обоих серверов: v1 (${portV1}), v2 (${portV2})`);
    
    const results = {
        v1: null,
        v2: null
    };
    
    // Устанавливаем v1
    progressCallback('📦 Установка AWG v1...');
    results.v1 = await installServer('v1', portV1, (msg) => {
        progressCallback(`[v1] ${msg}`);
    });
    
    if (!results.v1.success) {
        return {
            success: false,
            error: `Ошибка установки v1: ${results.v1.error}`,
            results
        };
    }
    
    // Устанавливаем v2
    progressCallback('📦 Установка AWG v2...');
    results.v2 = await installServer('v2', portV2, (msg) => {
        progressCallback(`[v2] ${msg}`);
    });
    
    if (!results.v2.success) {
        return {
            success: false,
            error: `Ошибка установки v2: ${results.v2.error}`,
            results
        };
    }
    
    progressCallback('✅ Оба сервера установлены!');
    
    return {
        success: true,
        results
    };
}

export {
    checkInstalledServers,
    getServerInfo,
    countClients,
    removeServer,
    generateServerKeys,
    createServerConfig,
    startContainer,
    installServer,
    installBothServers,
    CONTAINERS
};

// Made with Bob
