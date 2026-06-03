@IsTest
public class TestAssert {
    public static void equals(Object expected, Object actual, String message) {
        System.assertEquals(expected, actual, message);
    }

    public static void isTrue(Boolean condition, String message) {
        System.assert(condition, message);
    }

    public static void isFalse(Boolean condition, String message) {
        System.assert(!condition, message);
    }
}
