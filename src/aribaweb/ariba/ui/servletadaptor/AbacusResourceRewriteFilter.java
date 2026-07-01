/*
    Copyright 2026 Abacus, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

package ariba.ui.servletadaptor;

import ariba.ui.aribaweb.util.Log;
import ariba.util.log.Logger;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class AbacusResourceRewriteFilter implements Filter
{
    private static final Logger logger = Log.servletadaptor;

    private static final String AbacusDocrootPrefix = "/docroot/abacus/";
    private static final String AribaDocrootPrefix = "/docroot/ariba/";

    public void init (FilterConfig filterConfig) throws ServletException
    {
    }

    public void doFilter (ServletRequest servletRequest,
                          ServletResponse servletResponse,
                          FilterChain filterChain)
            throws IOException, ServletException
    {
        if (servletRequest instanceof HttpServletRequest &&
                servletResponse instanceof HttpServletResponse) {
            HttpServletRequest request = (HttpServletRequest)servletRequest;
            String requestUri = request.getRequestURI();
            // System.out.println("[AbacusResourceRewriteFilter] requestUri=" + requestUri);
            if (logger.isDebugEnabled()) {
                logger.debug("[AbacusResourceRewriteFilter] requestUri=%s", requestUri);
            }

            String contextPath = request.getContextPath();
            String relativeUri = requestUri;
            if (contextPath != null && !contextPath.isEmpty() &&
                    relativeUri != null && relativeUri.startsWith(contextPath)) {
                relativeUri = relativeUri.substring(contextPath.length());
            }

            if (relativeUri != null && relativeUri.startsWith(AbacusDocrootPrefix)) {
                String rewrittenUri = requestUri.replace(AbacusDocrootPrefix, AribaDocrootPrefix)
                                                  .replace("abacusweb", "aribaweb");
                String resourcePath = rewrittenUri;
                if (contextPath != null && !contextPath.isEmpty() &&
                        resourcePath.startsWith(contextPath)) {
                    resourcePath = resourcePath.substring(contextPath.length());
                }

                ServletContext context = request.getServletContext();
                InputStream in = context.getResourceAsStream(resourcePath);
                if (in != null) {
                    HttpServletResponse response = (HttpServletResponse)servletResponse;
                    String contentType = context.getMimeType(resourcePath);
                    if (contentType != null) {
                        response.setContentType(contentType);
                    }
                    response.setStatus(HttpServletResponse.SC_OK);
                    OutputStream out = response.getOutputStream();
                    // System.out.println("[AbacusResourceRewriteFilter] serving resource " + resourcePath);
                    if (logger.isDebugEnabled()) {
                        logger.debug("[AbacusResourceRewriteFilter] serving resource %s", resourcePath);
                    }
                    try {
                        byte[] buffer = new byte[8192];
                        int n;
                        while ((n = in.read(buffer)) > 0) {
                            out.write(buffer, 0, n);
                        }
                        out.flush();
                    }
                    finally {
                        in.close();
                    }
                    return;
                }
                // System.out.println("[AbacusResourceRewriteFilter] resource not found " + resourcePath);
                if (logger.isDebugEnabled()) {
                    logger.debug("[AbacusResourceRewriteFilter] resource not found %s", resourcePath);
                }
            }
        }
        filterChain.doFilter(servletRequest, servletResponse);
    }

    public void destroy ()
    {
    }
}
