package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.Order;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);
    private final JavaMailSender mailSender;
    private final MenuItemRepository menuItemRepository;

    @Value("${app.frontend.url:http://localhost:3000}") // Default URL if not set in properties
    private String frontendUrl;

    public void sendVerificationCode(String to, String code) throws MessagingException {
        if (!StringUtils.hasText(to) || !StringUtils.hasText(code)) {
            log.error("Invalid parameters for sending verification code. To: {}, Code: {}", to, code);
            throw new IllegalArgumentException("Email address and code must not be empty.");
        }

        log.info("Attempting to send verification code email to: {}", to);
        String subject = "Your Smart Canteen Verification Code";
        String content = buildVerificationEmailContent(code);

        sendHtmlEmail(to, subject, content);
        log.info("Verification email successfully sent to: {}", to);
    }

    public void sendPasswordResetEmail(String to, String token) throws MessagingException {
        if (!StringUtils.hasText(to) || !StringUtils.hasText(token)) {
            log.error("Invalid parameters for sending password reset. To: {}, Token: {}", to, token);
            throw new IllegalArgumentException("Email address and token must not be empty.");
        }

        log.info("Attempting to send password reset email to: {}", to);
        String subject = "Your Smart Canteen Password Reset Request";
        String resetUrl = frontendUrl + "/reset-password?token=" + token;
        String content = buildPasswordResetEmailContent(resetUrl);

        sendHtmlEmail(to, subject, content);
        log.info("Password reset email successfully sent to: {}", to);
    }

    public void sendOrderConfirmationEmail(Order order) throws MessagingException {
        log.info("Attempting to send order confirmation email for order #{}", order.getId());
        String subject = String.format("Your Smart Canteen Order Confirmation #%d", order.getId());
        String content = buildOrderConfirmationContent(order);

        sendHtmlEmail(order.getCustomer().getEmail(), subject, content);
        log.info("Successfully sent order confirmation email for order #{}", order.getId());
    }

    private void sendHtmlEmail(String to, String subject, String htmlContent) throws MessagingException {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlContent, true); // true indicates HTML content

            mailSender.send(message);
        } catch (MessagingException e) {
            log.error("Failed to send HTML email to: {}", to, e);
            throw e; // Re-throw to be handled by the calling service
        }
    }

    private String buildVerificationEmailContent(String code) {
        return String.format("""
            <html>
                <body style="font-family: Arial, sans-serif; text-align: center; color: #333;">
                    <h2>Smart Canteen Email Verification</h2>
                    <p>Thank you for registering. Please use the following code to verify your email address:</p>
                    <p style="font-size: 24px; font-weight: bold; letter-spacing: 2px; color: #0056b3;">%s</p>
                    <p>This code will expire in 10 minutes.</p>
                    <p><small>If you did not request this, please ignore this email.</small></p>
                </body>
            </html>
            """, code);
    }

    private String buildPasswordResetEmailContent(String resetUrl) {
        return String.format("""
            <html>
                <body style="font-family: Arial, sans-serif; color: #333;">
                    <h2>Smart Canteen Password Reset</h2>
                    <p>You are receiving this email because a password reset request was initiated for your account.</p>
                    <p>Please click the button below to reset your password:</p>
                    <a href="%s" style="background-color: #007bff; color: white; padding: 10px 20px; text-align: center; text-decoration: none; display: inline-block; border-radius: 5px;">Reset Password</a>
                    <p>This link will expire in 1 hour.</p>
                    <p>If you did not request a password reset, please disregard this email.</p>
                </body>
            </html>
            """, resetUrl);
    }

    private String buildOrderConfirmationContent(Order order) {
        // FIX: The keySet is already a Set<Long>. No mapping/parsing is needed.
        Set<Long> itemIds = order.getItems().keySet();

        Map<Long, MenuItem> itemMap = menuItemRepository.findAllById(itemIds).stream()
                .collect(Collectors.toMap(MenuItem::getId, item -> item));

        StringBuilder itemsHtml = new StringBuilder();
        // The Entry key is already a Long.
        for (Map.Entry<Long, Integer> entry : order.getItems().entrySet()) {
            // FIX: No need for parsing. Just get the item directly with the Long key.
            MenuItem item = itemMap.get(entry.getKey());

            String itemName = (item != null) ? item.getName() : "Unknown Item";
            BigDecimal itemPrice = (item != null) ? item.getPrice() : BigDecimal.ZERO;

            itemsHtml.append(String.format("<tr><td style='padding: 8px; border-bottom: 1px solid #ddd;'>%s</td><td style='padding: 8px; border-bottom: 1px solid #ddd; text-align: center;'>%d</td><td style='padding: 8px; border-bottom: 1px solid #ddd; text-align: right;'>₹%.2f</td></tr>",
                    itemName, entry.getValue(), itemPrice));
        }

        return String.format("""
            <html><body style='font-family: Arial, sans-serif; color: #333;'>
            <div style='max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;'>
                <h2 style='text-align: center; color: #0056b3;'>Thank you for your order!</h2>
                <p>Hi %s,</p>
                <p>Your order with ID <strong>#%d</strong> has been successfully completed. Here is your receipt:</p>
                <table style='width: 100%%; border-collapse: collapse; margin-top: 20px;'>
                    <thead><tr>
                        <th style='padding: 8px; border-bottom: 2px solid #333; text-align: left;'>Item</th>
                        <th style='padding: 8px; border-bottom: 2px solid #333; text-align: center;'>Quantity</th>
                        <th style='padding: 8px; border-bottom: 2px solid #333; text-align: right;'>Price</th>
                    </tr></thead>
                    <tbody>%s</tbody>
                </table>
                <h3 style='text-align: right; margin-top: 20px;'>Total: ₹%.2f</h3>
                <p style='text-align: center; margin-top: 30px;'>We hope you enjoy your meal!</p>
            </div></body></html>
            """, order.getCustomer().getFullName(), order.getId(), itemsHtml.toString(), order.getTotalAmount());
    }
}