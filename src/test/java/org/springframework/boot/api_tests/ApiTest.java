
package org.springframework.boot.api_tests;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
// import com.intuit.karate.http.HttpServer;
// import com.intuit.karate.http.ServerConfig;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ApiTest {

	@Test
	void testAll() {
		String apiHostServer = System.getenv().getOrDefault("API_HOST", "http://localhost:8080");
		String authtoken = System.getenv().getOrDefault("AUTH_TOKEN", "dummy AUTH_TOKEN");
		Results results = Runner.path("classpath:org/springframework/boot/api_tests")
			.systemProperty("url.base", apiHostServer)
			.systemProperty("AUTH_TOKEN", authtoken)
			.parallel(1);
		assertEquals(0, results.getFailCount(), results.getErrorMessages());
	}

}
