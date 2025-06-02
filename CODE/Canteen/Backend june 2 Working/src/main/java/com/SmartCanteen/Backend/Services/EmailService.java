package com.SmartCanteen.Backend.Services;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);
    private final JavaMailSender mailSender;

    public void sendVerificationCode(String to, String code) throws MessagingException {
        if (!StringUtils.hasText(to) || !StringUtils.hasText(code)) {
            log.error("Invalid email parameters - to: {}, code: {}", to, code);
            throw new IllegalArgumentException("Email and code must not be empty");
        }

        log.info("Sending verification code to: {}", to);  // Don't log the code for security

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(to);
            helper.setSubject("Email Verification Code");
            helper.setText(buildEmailContent(code), true);

            mailSender.send(message);
            log.info("Verification email sent successfully to: {}", to);
        } catch (MessagingException e) {
            log.error("Failed to send verification email to: {}", to, e);
            throw e;  // Re-throw or handle differently as needed
        }
    }

    private String buildEmailContent(String code) {
        return """
            <html>
                <body>
                    <h2>Smart Canteen Email Verification</h2>
                    <p>Your verification code is: <strong>%s</strong></p>
                    <p>This code will expire in 10 minutes.</p>
                </body>
            </html>
            """.formatted(code);
    }
}