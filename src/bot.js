import TelegramBot from 'node-telegram-bot-api';
import { config } from './config.js';
import { resolveDomain, resolveMultipleDomains } from './dnsResolver.js';
import {
  generateBatchFile,
  saveBatchFile,
  generateFilename,
  generateMultipleDomainsFilename
} from './fileGenerator.js';
import { AntiFlood } from './antiflood.js';

export class RouteBot {
  constructor() {
    this.bot = new TelegramBot(config.telegramToken, { polling: true });
    // Anti-flood: max 5 requests per minute
    this.antiFlood = new AntiFlood(10, 60000);
    this.antiFlood.startCleanup();
    this.setupHandlers();
  }

  setupHandlers() {
    // Start command
    this.bot.onText(/\/start/, (msg) => {
      const chatId = msg.chat.id;
      const welcomeMessage = `
🚀 *Добро пожаловать!*

*Как использовать:*
📝 Отправьте один домен: \`rutube.ru\`
📝 Отправьте несколько доменов (каждый с новой строки):
\`\`\`
rutube.ru
ozon.ru
google.com
\`\`\`

*Команды:*
/start - Показать это сообщение
/help - Справка
      `;
      
      this.bot.sendMessage(chatId, welcomeMessage, { parse_mode: 'Markdown' });
    });

    // Help command
    this.bot.onText(/\/help/, (msg) => {
      const chatId = msg.chat.id;
      const helpMessage = `
*Справка по использованию бота*

*Формат ввода:*
• Один домен: просто отправьте домен:
\`rutube.ru\`

• Несколько доменов: каждый домен с новой строки
\`\`\`
rutube.ru
ozon.ru
google.com
\`\`\`
      `;
      
      this.bot.sendMessage(chatId, helpMessage, { parse_mode: 'Markdown' });
    });

    // Handle text messages (domains)
    this.bot.on('message', async (msg) => {
      // Skip commands
      if (msg.text && msg.text.startsWith('/')) {
        // Show start message for unknown commands
        if (!msg.text.match(/^\/(start|help)$/)) {
          const chatId = msg.chat.id;
          const welcomeMessage = `
🤖 *Добро пожаловать в Route Generator Bot!*

Этот бот создает .bat файлы с командами маршрутизации для доменов.

*Как использовать:*
📝 Отправьте один домен: \`rutube.ru\`
📝 Отправьте несколько доменов (каждый с новой строки):
\`\`\`
rutube.ru
ozon.ru
google.com
\`\`\`

Бот разрешит DNS и создаст файл с командами route ADD для всех найденных IP адресов (IPv4).

*Команды:*
/start - Показать это сообщение
/help - Справка
          `;
          
          this.bot.sendMessage(chatId, welcomeMessage, { parse_mode: 'Markdown' });
        }
        return;
      }

      const chatId = msg.chat.id;
      const text = msg.text;

      if (!text || text.trim() === '') {
        return;
      }

      await this.processDomains(chatId, text);
    });

    // Error handling
    this.bot.on('polling_error', (error) => {
      console.error('Polling error:', error);
    });
  }

  async processDomains(chatId, text) {
    try {
      // Check anti-flood
      const userId = chatId;
      const limitCheck = this.antiFlood.checkLimit(userId);
      
      if (!limitCheck.allowed) {
        this.bot.sendMessage(
          chatId,
          `⏳ Слишком много запросов. Подождите ${limitCheck.remainingTime} секунд.`
        );
        return;
      }

      // Parse domains from text
      const domains = text
        .split('\n')
        .map(line => line.trim())
        .filter(line => line.length > 0);

      if (domains.length === 0) {
        this.bot.sendMessage(chatId, '❌ Не найдено доменов для обработки.');
        return;
      }

      // Validate domains
      const domainRegex = /^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/;
      const invalidDomains = domains.filter(domain => {
        const cleanDomain = domain
          .replace(/^https?:\/\//, '')
          .replace(/^www\./, '')
          .split('/')[0]
          .split(':')[0];
        return !domainRegex.test(cleanDomain);
      });

      if (invalidDomains.length > 0) {
        this.bot.sendMessage(
          chatId,
          `❌ Неправильный формат доменов:\n${invalidDomains.join('\n')}\n\n` +
          `*Как использовать:*\n` +
          `📝 Отправьте один домен: \`rutube.ru\`\n` +
          `📝 Отправьте несколько доменов (каждый с новой строки):\n` +
          `\`\`\`\nrutube.ru\nozon.ru\ngoogle.com\n\`\`\`\n\n` +
          `*Команды:*\n` +
          `/start - Показать это сообщение\n` +
          `/help - Справка`,
          { parse_mode: 'Markdown' }
        );
        return;
      }

      // Send processing message
      const processingMsg = await this.bot.sendMessage(
        chatId, 
        `⏳ Обрабатываю ${domains.length} домен(ов)...`
      );

      // Resolve domains
      let domainsMap;
      if (domains.length === 1) {
        const addresses = await resolveDomain(domains[0]);
        domainsMap = new Map([[domains[0], addresses]]);
      } else {
        domainsMap = await resolveMultipleDomains(domains);
      }

      // Check if any domains were resolved
      if (domainsMap.size === 0) {
        this.bot.editMessageText(
          '❌ Не удалось разрешить ни один домен. Проверьте правильность ввода.',
          { chat_id: chatId, message_id: processingMsg.message_id }
        );
        return;
      }

      // Generate statistics
      let totalIPs = 0;
      for (const addresses of domainsMap.values()) {
        totalIPs += addresses.ipv4.length;
      }

      // Generate batch file
      const filename = domains.length === 1 
        ? generateFilename(domains[0])
        : generateMultipleDomainsFilename(domains);

      const content = generateBatchFile(domainsMap, filename);
      const filepath = saveBatchFile(content, filename);

      // Delete processing message
      await this.bot.deleteMessage(chatId, processingMsg.message_id);

      // Send file without caption
      await this.bot.sendDocument(chatId, filepath);

      // Send domains list (max 5) with statistics
      const domainsList = Array.from(domainsMap.keys());
      const displayDomains = domainsList.slice(0, 5);
      let domainsMessage = '🌐 Домены:\n';
      
      displayDomains.forEach(domain => {
        const ipCount = domainsMap.get(domain).ipv4.length;
        domainsMessage += `• ${domain} (${ipCount} IP)\n`;
      });
      
      if (domainsList.length > 5) {
        domainsMessage += `\n... и еще ${domainsList.length - 5}`;
      }

      // Add statistics
      domainsMessage += `\n📊 Статистика:\n`;
      domainsMessage += `Всего доменов: ${domainsMap.size}\n`;
      domainsMessage += `Всего IP адресов: ${totalIPs}`;

      this.bot.sendMessage(chatId, domainsMessage);

    } catch (error) {
      console.error('Error processing domains:', error);
      this.bot.sendMessage(
        chatId, 
        `❌ Произошла ошибка при обработке: ${error.message}`
      );
    }
  }

  start() {
    console.log('Bot started successfully!');
    console.log('Waiting for messages...');
  }
}

// Made with Bob
