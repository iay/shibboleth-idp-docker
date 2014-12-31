import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.Key;
import java.security.MessageDigest;
import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.SecretKeySpec;

class Test {

    private static void testSHA256() {
	MessageDigest md;
	try {
	    md = MessageDigest.getInstance("SHA-256");
	    System.out.println("SHA-256 algorithm is present.");
	} catch (NoSuchAlgorithmException e) {
	    System.out.println("SHA-256 algorithm not present.");
	}
    }

    private static void testAES(final int keySize)
	throws NoSuchAlgorithmException, NoSuchPaddingException {
	final String prefix = "AES with " + keySize + "-bit key";
	// key, contents are irrelevant
	final byte[] keyValue = new byte[keySize/8];
	final Key key =  new SecretKeySpec(keyValue, "AES");
	final Cipher c1 = Cipher.getInstance("AES");
	try {
	    c1.init(Cipher.ENCRYPT_MODE, key);
	    System.out.println(prefix + " OK.");
	} catch (final InvalidKeyException e) {
	    System.out.println(prefix + " not permitted.");
	}
    }

    public static void main(String[] args) throws Exception {
       System.out.println("Testing for cryptographic policies.\n");
       testAES(128);
       testAES(256);
       testSHA256();
       System.out.println("\nTests complete.");
   }

}
