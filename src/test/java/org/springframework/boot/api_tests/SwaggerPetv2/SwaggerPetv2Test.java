
package org.springframework.boot.api_tests;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
// import com.intuit.karate.http.HttpServer;
// import com.intuit.karate.http.ServerConfig;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class SwaggerPetv2Test {

	@Test
	void testAll() {
		String urlbase = System.getenv().get("URL_BASE");
		String authtoken = System.getenv().get("AUTH_TOKEN");
		String apikey = System.getenv().get("API_KEY");
		String petstoreauth = System.getenv().get("PETSTORE_AUTH");
		Results results = Runner.path("src/test/java/org/springframework/boot/api_tests/SwaggerPetv2")
			.systemProperty("URL_BASE", urlbase)
			.systemProperty("AUTH_TOKEN", authtoken)
			.systemProperty("API_KEY", apikey)
			.systemProperty("PETSTORE_AUTH", petstoreauth)
			.reportDir("testReport")
			.parallel(1);
		assertEquals(0, results.getFailCount(), results.getErrorMessages());
	}

}
