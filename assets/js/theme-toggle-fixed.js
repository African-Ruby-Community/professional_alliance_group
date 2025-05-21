// Apply theme based on system preference or fixed setting
(function() {
  "use strict";

  // Force dark mode by default
  const forceDarkMode = true; // Set to true to force dark mode, false for light mode

  if (forceDarkMode) {
    document.body.classList.add('dark-mode');
    
    // Try to update theme-dependent elements immediately
    try {
      // Update logos immediately without waiting for DOMContentLoaded
      const logoElements = document.querySelectorAll('.theme-sensitive-logo');
      if (logoElements.length > 0) {
        logoElements.forEach(function(logo) {
          const darkSrc = logo.getAttribute('data-dark-src');
          if (darkSrc) {
            logo.src = darkSrc;
          }
        });
      }
    } catch (e) {
      console.log('Will update theme elements on DOMContentLoaded');
    }

    // Also update any theme-dependent elements when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
      updateThemeDependentElements(true);
    });
  }
})();

// Function to update theme-dependent elements like logos
function updateThemeDependentElements(isDarkMode) {
  // Get all logo elements that should change with theme
  const logoElements = document.querySelectorAll('.theme-sensitive-logo');

  logoElements.forEach(function(logo) {
    if (isDarkMode) {
      // Use dark mode logo (aglogo.png)
      logo.src = logo.getAttribute('data-dark-src') || logo.src;
    } else {
      // Use light mode logo (ag_logo_coloured.png or as specified)
      logo.src = logo.getAttribute('data-light-src') || logo.src;
    }
  });
}

// Initialize theme when DOM is ready
(function ($) {
  "use strict";

  $(document).ready(function() {
    // Force dark mode by default
    const forceDarkMode = true; // Set to true to force dark mode, false for light mode
    
    if (forceDarkMode) {
      $('body').addClass('dark-mode');
      updateThemeDependentElements(true);
    } else {
      $('body').removeClass('dark-mode');
      updateThemeDependentElements(false);
    }
  });
})(jQuery);