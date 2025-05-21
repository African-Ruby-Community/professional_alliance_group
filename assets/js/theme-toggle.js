// Immediately apply theme to prevent flicker
(function() {
  "use strict";

  // Flag to disable dark mode functionality until it's fixed
  const enableDarkMode = false; // Set to false to disable dark mode, true to enable

  // If dark mode is disabled, remove any saved preference and force light mode
  if (!enableDarkMode) {
    localStorage.removeItem('darkMode');
    document.body.classList.remove('dark-mode');
    return; // Exit early - no need to check saved theme
  }

  // Get saved theme preference
  const savedTheme = localStorage.getItem('darkMode');

  // Apply theme immediately if saved
  if (savedTheme === 'true') {
    document.body.classList.add('dark-mode');

    // Try to update theme-dependent elements immediately
    // This helps prevent flickering of elements like logos
    try {
      // Try to update logos immediately without waiting for DOMContentLoaded
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
      // If there's an error, we'll still update elements on DOMContentLoaded
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

// Full theme functionality after DOM is ready
(function ($) {
  "use strict";

  // Function to set the theme
  function setTheme(isDarkMode) {
    if (isDarkMode) {
      $('body').addClass('dark-mode');
      $('.theme-toggle i').removeClass('fa-moon').addClass('fa-sun');
    } else {
      $('body').removeClass('dark-mode');
      $('.theme-toggle i').removeClass('fa-sun').addClass('fa-moon');
    }
    // Save the theme preference to localStorage
    localStorage.setItem('darkMode', isDarkMode);

    // Update theme-dependent elements like logos
    updateThemeDependentElements(isDarkMode);
  }

  // Function to toggle the theme
  function toggleTheme() {
    // Flag to disable dark mode functionality until it's fixed
    const enableDarkMode = false; // Set to false to disable dark mode, true to enable

    // If dark mode is disabled, do nothing
    if (!enableDarkMode) {
      return;
    }

    const isDarkMode = $('body').hasClass('dark-mode');
    setTheme(!isDarkMode);
  }

  // Initialize theme based on localStorage or system preference
  $(document).ready(function() {
    // Flag to disable dark mode functionality until it's fixed
    const enableDarkMode = false; // Set to false to disable dark mode, true to enable

    // If dark mode is disabled, force light mode and disable toggle functionality
    if (!enableDarkMode) {
      $('body').removeClass('dark-mode');
      $('.theme-toggle').css('display', 'none'); // Hide the toggle button
      updateThemeDependentElements(false);
      return; // Exit early - no need to check saved theme
    }

    // Check if user has a saved preference
    const savedTheme = localStorage.getItem('darkMode');

    if (savedTheme !== null) {
      // Use saved preference (already applied to body, just update the icon)
      if (savedTheme === 'true') {
        $('.theme-toggle i').removeClass('fa-moon').addClass('fa-sun');
      }
    } else {
      // Check for system preference
      const prefersDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
      setTheme(prefersDarkMode);

      // Listen for changes in system preference
      if (window.matchMedia) {
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
          if (localStorage.getItem('darkMode') === null) {
            setTheme(e.matches);
          }
        });
      }
    }

    // Add click event to theme toggle button
    $('.theme-toggle').on('click', function(e) {
      // Flag to disable dark mode functionality until it's fixed
      const enableDarkMode = false; // Set to false to disable dark mode, true to enable

      // If dark mode is disabled, prevent default action and do nothing
      if (!enableDarkMode) {
        e.preventDefault();
        return;
      }

      toggleTheme();
    });
  });
})(jQuery);
