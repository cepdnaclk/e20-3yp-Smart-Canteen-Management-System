package com.SmartCanteen.Backend.Services;



import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {
    @Autowired
    private JavaMailSender mailSender;

    public void sendVerificationEmail(String toEmail, String verificationCode) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom("noreply@smartcanteen.com");
        message.setTo(toEmail);
        message.setSubject("Smart Canteen - Email Verification");
        message.setText("Your verification code is: " + verificationCode);

        mailSender.send(message);
    }
}