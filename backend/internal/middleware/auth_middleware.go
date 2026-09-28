package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"fmcg-pos-backend/internal/services"
)

// AuthMiddleware validates JWT Bearer tokens and injects authenticated user/store identity into Gin context
func AuthMiddleware(jwtService *services.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Authorization header is required",
			})
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Authorization header must be Bearer token",
			})
			return
		}

		tokenStr := strings.TrimSpace(parts[1])
		claims, err := jwtService.ValidateAccessToken(tokenStr)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": err.Error(),
			})
			return
		}

		// Inject verified claims into context
		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Set("role", claims.Role)
		c.Set("store_id", claims.StoreID)
		c.Set("member_role", claims.MemberRole)
		c.Set("claims", claims)

		c.Next()
	}
}

// RequireRole enforces role-based access control based on user's system role or member role
func RequireRole(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		roleVal, _ := c.Get("role")
		role, _ := roleVal.(string)

		memberRoleVal, _ := c.Get("member_role")
		memberRole, _ := memberRoleVal.(string)

		for _, allowed := range allowedRoles {
			if strings.EqualFold(role, allowed) || strings.EqualFold(memberRole, allowed) {
				c.Next()
				return
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"error":   "forbidden",
			"message": "You do not have permission to access this resource",
		})
	}
}

// GetContextStoreID retrieves the active store ID from the request context
func GetContextStoreID(c *gin.Context) string {
	if storeID, ok := c.Get("store_id"); ok {
		if s, ok := storeID.(string); ok && s != "" {
			return s
		}
	}
	// Fallback to header or query if not in JWT
	if headerStore := c.GetHeader("X-Store-ID"); headerStore != "" {
		return headerStore
	}
	return c.Query("store_id")
}
