package com.SmartCanteen.Backend.Controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/uploads")
public class FileUploadController {

    private static final String UPLOAD_DIR = "uploads/";

    @PostMapping("/")  // Changed to root path
    public ResponseEntity<?> uploadMenuItemImage(@RequestParam("file") MultipartFile file) {
        try {
            // Create directory if missing
            Files.createDirectories(Paths.get(UPLOAD_DIR));

            // Generate unique filename
            String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();

            // Save file
            Path path = Paths.get(UPLOAD_DIR + filename);
            Files.write(path, file.getBytes());

            // Return JSON with filePath
            return ResponseEntity.ok(Map.of("filePath", filename));

        } catch (IOException e) {
            // Return structured error
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to upload image"));
        }
    }
}
