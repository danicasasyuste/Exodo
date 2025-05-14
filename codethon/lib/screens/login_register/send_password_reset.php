<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php';  // Asegúrate de cargar PHPMailer

// Configura tu servidor de correo
$host = 'smtp.gmail.com';  // Cambia esto por el host de tu servidor SMTP (ej. smtp.gmail.com)
$username = 'your-email@example.com';  // Tu correo
$password = 'your-email-password';  // La contraseña de tu correo
$fromEmail = 'your-email@example.com';  // Correo de origen
$fromName = 'Recuperación de Contraseña';  // Nombre que aparece en el correo

// Obtener el correo del cliente desde la solicitud
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $email = $_POST['email'];
    
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['status' => 'error', 'message' => 'Correo electrónico no válido']);
        exit;
    }
    
    // Generar un enlace de restablecimiento de contraseña (puedes implementar esto más tarde)
    $resetLink = 'https://tu-sitio-web.com/reset-password?email=' . urlencode($email);

    // Crear el objeto PHPMailer
    $mail = new PHPMailer(true);

    try {
        // Configurar el servidor SMTP
        $mail->isSMTP();
        $mail->Host = $host;
        $mail->SMTPAuth = true;
        $mail->Username = $username;
        $mail->Password = $password;
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = 587;

        // Configurar los detalles del correo
        $mail->setFrom($fromEmail, $fromName);
        $mail->addAddress($email);

        // Contenido del correo
        $mail->isHTML(true);
        $mail->Subject = 'Recuperación de Contraseña';
        $mail->Body    = "<h3>Recuperación de Contraseña</h3><p>Para restablecer su contraseña, haga clic en el siguiente enlace:</p><a href='$resetLink'>$resetLink</a>";

        // Enviar el correo
        $mail->send();

        echo json_encode(['status' => 'success', 'message' => 'Correo enviado con éxito']);
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => "Error al enviar el correo: {$mail->ErrorInfo}"]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Método no permitido']);
}
?>
