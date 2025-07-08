package com.SmartCanteen.Backend.Controllers;

import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.*;

@RestController
@RequestMapping("/api")
public class UploadController {

    private static final String UPLOAD_DIR = "uploads/";

    @PostMapping("/upload")
    public ResponseEntity<String> uploadImage(@RequestParam("image") MultipartFile image) {
        if (image.isEmpty()) {
            return ResponseEntity.badRequest().body("No image uploaded");
        }

        try {
            // Save the image locally
            File uploadDir = new File(UPLOAD_DIR);
            if (!uploadDir.exists()) uploadDir.mkdirs();

            String filename = StringUtils.cleanPath(image.getOriginalFilename());
            Path filepath = Paths.get(UPLOAD_DIR, filename);
            Files.copy(image.getInputStream(), filepath, StandardCopyOption.REPLACE_EXISTING);

            // Send to FastAPI for detection
            String fastApiUrl = "http://localhost:8080/detect"; // Update if different host

            RestTemplate restTemplate = new RestTemplate();

            // Prepare the file as multipart
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            FileSystemResource resource = new FileSystemResource(filepath.toFile());
            body.add("image", resource);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            ResponseEntity<String> response = restTemplate.postForEntity(fastApiUrl, requestEntity, String.class);

            return ResponseEntity.ok("People Count: " + response.getBody());

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Upload error: " + e.getMessage());
        }
    }

}
