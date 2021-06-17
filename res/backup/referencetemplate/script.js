(function() {
    const navbarResetBtn = document.querySelector('#appNavbar #searchReset'),
        navbarSearchInput = document.querySelector('#appNavbar #navSearch');

    navbarResetBtn.addEventListener('click', function(e) {
        navbarSearchInput.value = '';
    });
})();