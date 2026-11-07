 // Keywords and phrases commonly associated with phishing emails
const SUSPICIOUS_PHRASES = [
  "lottery", "prize", "winner", "urgent",
  "click here", "free", "offer", "password",
  "bank account", "limited time", "risk-free",
  "guaranteed", "act now", "exclusive deal",
  "verify your account", "claim your reward",
  "investment opportunity", "get rich quick",
  "work from home", "no risk", "instant access",
  "confidential information", "personal information",
  "sensitive data"
];

// Reference domains used to identify potential impersonation
const TRUSTED_DOMAINS = [
  "paypal.com", "google.com", "microsoft.com",
  "amazon.com", "apple.com"
];

const SENDER_DOMAINS = [
  ...TRUSTED_DOMAINS,
  "gmail.com", "yahoo.com", "outlook.com",
  "hotmail.com", "icloud.com"
];

// File extensions considered potentially dangerous
const DANGEROUS_EXTENSIONS = [
  ".exe", ".bat", ".cmd", ".scr", ".pif",
  ".js", ".vbs", ".jar", ".com", ".cpl"
];

// Checks whether two domain names differ by exactly one character
function isOneCharacterDifferent(first, second) {
  if (first.length !== second.length) {
    return false;
  }

  let differences = 0;

  for (let i = 0; i < first.length; i++) {
    if (first[i] !== second[i]) {
      differences++;
    }
  }

  return differences === 1;
}

// Escapes HTML characters before displaying user controlled content
function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// Analyzes email content, sender domain, and attachment filenames
function analyzeEmail(content, sender, attachments) {
  const text = content.toLowerCase();

  // Detect suspicious phrases without counting repeated occurrences
  const words = SUSPICIOUS_PHRASES.filter(
    phrase => text.includes(phrase)
  );

  // Extract URLs and check for IP addresses, lookalike domains, and usernames
  const links = [];
  const urls = content.match(/https?:\/\/[^\s<>"]+/gi) || [];

  for (const originalUrl of urls) {
    const url = originalUrl.replace(/[.,);!?]+$/, "");

    try {
      const match = url.match(
        /^https?:\/\/(?:([^/?#@]+)@)?([^/:?#@]+)(?::\d+)?(?:[/?#]|$)/i
      );

      if (!match) {
        continue;
      }

      const hostname = match[2]
        .toLowerCase()
        .replace(/^www\./, "");

      const isIpAddress =
        /^(?:\d{1,3}\.){3}\d{1,3}$/.test(hostname);

      const isLookalike = TRUSTED_DOMAINS.some(
        domain => isOneCharacterDifferent(hostname, domain)
      );

      const hasUsername = Boolean(match[1]);

      if (isIpAddress || isLookalike || hasUsername) {
        links.push(url);
      }
    } catch (error) {
      // Skip URLs that cannot be processed
    }
  }

  // Detect sender domains that resemble known email providers or services
  const senders = [];
  const emailMatch = sender.match(
    /[A-Z0-9._%+-]+@([A-Z0-9.-]+\.[A-Z]{2,})/i
  );

  if (emailMatch) {
    const senderDomain = emailMatch[1].toLowerCase();

    for (const domain of SENDER_DOMAINS) {
      if (isOneCharacterDifferent(senderDomain, domain)) {
        senders.push(
          `Suspicious sender: ${senderDomain} resembles ${domain}`
        );
      }
    }
  }

  // Inspect attachment filenames without accessing their contents
  const suspiciousAttachments = attachments.filter(
    filename => DANGEROUS_EXTENSIONS.some(
      extension => filename.toLowerCase().endsWith(extension)
    )
  );

  // Calculate a weighted risk score maximum at 100
  const score = Math.min(
    words.length * 10 +
    links.length * 30 +
    senders.length * 40 +
    suspiciousAttachments.length * 25,
    100
  );

  const riskLevel =
    score >= 60 ? "High" :
    score >= 30 ? "Medium" : "Low";

  return {
    score,
    riskLevel,
    words,
    links,
    senders,
    attachments: suspiciousAttachments
  };
}

// Gmail contextual trigger: analyzes the currently opened message
function onGmailMessageOpen(e) {
  const messageId = e.gmail.messageId;
  const accessToken = e.gmail.accessToken;

  GmailApp.setCurrentMessageAccessToken(accessToken);

  const message = GmailApp.getMessageById(messageId);

  const attachments = message.getAttachments().map(
    attachment => attachment.getName()
  );

  const result = analyzeEmail(
    message.getPlainBody(),
    message.getFrom(),
    attachments
  );

  // Build the results card displayed in the Gmail sidebar
  const card = CardService.newCardBuilder();

  card.setHeader(
    CardService.newCardHeader()
      .setTitle("Phishing Detector")
      .setSubtitle("Email Security Analysis")
  );

  const summary = CardService.newCardSection()
    .setHeader("Scan Results");

  summary.addWidget(
    CardService.newTextParagraph().setText(
      `<b>Risk Score:</b> ${result.score}/100`
    )
  );

  summary.addWidget(
    CardService.newTextParagraph().setText(
      `<b>Risk Level:</b> ${result.riskLevel}`
    )
  );

  // Combine all detected indicators into a single display list
  const indicators = [
    ...result.words.map(item => `Suspicious phrase: ${item}`),
    ...result.links.map(item => `Suspicious link: ${item}`),
    ...result.senders,
    ...result.attachments.map(
      item => `Suspicious attachment: ${item}`
    )
  ];

  summary.addWidget(
    CardService.newTextParagraph().setText(
      `<b>Indicators detected:</b> ${indicators.length}`
    )
  );

  card.addSection(summary);

  // Display up to ten indicators to keep the sidebar readable
  const details = CardService.newCardSection()
    .setHeader("Detection Details");

  if (indicators.length === 0) {
    details.addWidget(
      CardService.newTextParagraph().setText(
        "No suspicious indicators were detected by the current rules."
      )
    );
  } else {
    for (const indicator of indicators.slice(0, 10)) {
      details.addWidget(
        CardService.newTextParagraph().setText(
          escapeHtml(indicator)
        )
      );
    }

    if (indicators.length > 10) {
      details.addWidget(
        CardService.newTextParagraph().setText(
          `And ${indicators.length - 10} additional indicators.`
        )
      );
    }
  }

  card.addSection(details);

  // Clarify that the detection cannot guarantee email safety
  card.addSection(
    CardService.newCardSection().addWidget(
      CardService.newTextParagraph().setText(
        "Rule-based analysis only. A low score does not guarantee that an email is safe."
      )
    )
  );

  return card.build();
}
