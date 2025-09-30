
/**
 * Simple Java application for testing mock energy measurement interface.
 * Creates different workload patterns to validate GC behavior simulation.
*/
public class SimpleGCTest {
    
    public static void main(String[] args) {
        String workload = args.length > 0 ? args[0] : "medium";
        
        System.out.println("Starting GC test with workload: " + workload);
        long startTime = System.currentTimeMillis();
        
        switch (workload.toLowerCase()) {
            case "light":
                lightWorkload();
                break;
            case "medium":
                mediumWorkload();
                break;
            case "heavy":
                heavyWorkload();
                break;
            default:
                System.err.println("Unknown workload: " + workload);
                System.exit(1);
        }
        
        long duration = System.currentTimeMillis() - startTime;
        System.out.println("Test completed in " + duration + "ms");
    }
    
    /**
     * Light workload - minimal allocation, short runtime
     */
    private static void lightWorkload() {
        java.util.List<String> tempStrings = new java.util.ArrayList<>();
        
        for (int i = 0; i < 1000; i++) {
            tempStrings.add("Test string " + i);
            if (i % 100 == 0) {
                System.gc(); // Explicit GC to trigger collection
            }
        }
        
        // Use the strings to prevent optimization
        System.out.println("Generated " + tempStrings.size() + " test strings");
        
        // Small delay to ensure measurable execution time
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    /**
     * Medium workload - moderate allocation, medium runtime
     */
    private static void mediumWorkload() {
        java.util.List<String> data = new java.util.ArrayList<>();
        
        for (int i = 0; i < 10000; i++) {
            data.add("Data item " + i + " with some additional text to increase object size");
            
            // Periodically clear and rebuild to trigger GC
            if (i % 1000 == 0) {
                data.clear();
                System.gc();
            }
        }
        
        // Some computation to increase CPU usage
        int sum = 0;
        for (int i = 0; i < 100000; i++) {
            sum += Math.sqrt(i);
        }
        System.out.println("Computation result: " + sum);
    }
    
    /**
     * Heavy workload - significant allocation, longer runtime
     */
    private static void heavyWorkload() {
        java.util.List<java.util.List<String>> nestedData = new java.util.ArrayList<>();
        
        for (int outer = 0; outer < 100; outer++) {
            java.util.List<String> innerList = new java.util.ArrayList<>();
            
            for (int inner = 0; inner < 1000; inner++) {
                innerList.add("Heavy data " + outer + ":" + inner + 
                             " - Creating significant memory pressure with longer strings");
            }
            
            nestedData.add(innerList);
            
            // Force GC every 10 iterations
            if (outer % 10 == 0) {
                System.gc();
                // Add some CPU work between allocations
                fibonacci(25); // Recursive fibonacci to stress the system
            }
        }
        
        System.out.println("Created " + nestedData.size() + " nested lists");
    }
    
    /**
     * Recursive fibonacci to add CPU load and call stack pressure
     */
    private static long fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }
}