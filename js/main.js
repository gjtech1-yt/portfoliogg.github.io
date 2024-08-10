document.addEventListener('contextmenu', function(e) {
    e.preventDefault(); // Previne o menu de contexto (botão direito)
});

document.addEventListener('mousedown', function(e) {
    if (e.button === 2) { // Botão direito do mouse
        e.preventDefault();
    }
});

        document.addEventListener('DOMContentLoaded', function() {
            const voltaraotopoButton = document.getElementById('voltaraotopo');

            window.addEventListener('scroll', function() {
                if (window.scrollY > 200) { 
                    voltaraotopoButton.classList.add('visible');
                } else {
                    voltaraotopoButton.classList.remove('visible');
                }
            });

            voltaraotopoButton.addEventListener('click', function(event) {
                event.preventDefault();
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                });
            });
        });

        const faders = document.querySelectorAll('.fade-up');

        const appearOptions = {
            threshold: 0,
            rootMargin: "0px 0px -100px 0px"
        };

        const appearOnScroll = new IntersectionObserver(function(entries, appearOnScroll) {
            entries.forEach(entry => {
                if (!entry.isIntersecting) {
                    return;
                } else {
                    entry.target.classList.add('visible');
                    appearOnScroll.unobserve(entry.target);
                }
            });
        }, appearOptions);

        faders.forEach(fader => {
            appearOnScroll.observe(fader);
        });

document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();

                document.querySelector(this.getAttribute('href')).scrollIntoView({
                    behavior: 'smooth'
                });
            });
        });

        window.onload = function() {
            document.querySelector('.photoshop').style.width = '100%';
            document.querySelector('.blender').style.width = '75%';
            document.querySelector('.premiere').style.width = '85%';
            document.querySelector('.illustrator').style.width = '75%';
            document.querySelector('.html').style.width = '75%';
            document.querySelector('.css').style.width = '85%';
            document.querySelector('.javascript').style.width = '25%';
            document.querySelector('.vegaspro').style.width = '90%';
            document.querySelector('.neutralinojs').style.width = '75%';
        }