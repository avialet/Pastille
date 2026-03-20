// ============================================
// LUCARNE — Animations GSAP
// Cohérent avec Chuchotte & Écran Total
// ============================================

gsap.registerPlugin(ScrollTrigger);

// ============================================
// Navbar scroll effect
// ============================================
window.addEventListener('scroll', () => {
    const navbar = document.getElementById('navbar');
    if (window.scrollY > 40) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// ============================================
// Hero entrance
// ============================================
const heroTl = gsap.timeline({ defaults: { ease: 'power3.out' } });

heroTl
    .to('.hero-content', {
        opacity: 1,
        y: 0,
        duration: 0.8,
        delay: 0.2
    })
    .to('.hero-visual', {
        opacity: 1,
        scale: 1,
        duration: 0.8
    }, '-=0.4');

// ============================================
// Hero Lucarne animation sequence
// ============================================
const lucarneTl = gsap.timeline({
    defaults: { ease: 'power2.out' },
    delay: 1.2,
    repeat: -1,
    repeatDelay: 3
});

lucarneTl
    // 1. Selection rectangle appears
    .to('.hero-selection', {
        opacity: 1,
        duration: 0.3
    })
    .to('.hero-selection', {
        width: 140,
        height: 90,
        duration: 0.6,
        ease: 'power1.inOut'
    })
    // 2. Selection disappears, Lucarne pops in
    .to('.hero-selection', {
        opacity: 0,
        duration: 0.2
    })
    .to('.hero-lucarne', {
        opacity: 1,
        scale: 1,
        duration: 0.5,
        ease: 'back.out(1.7)'
    })
    // 3. Float for a moment
    .to('.hero-lucarne', {
        y: -8,
        duration: 1.2,
        ease: 'sine.inOut',
        yoyo: true,
        repeat: 1
    })
    // 4. Fade out and reset
    .to('.hero-lucarne', {
        opacity: 0,
        scale: 0.8,
        duration: 0.4
    })
    .set('.hero-lucarne', { scale: 0.6, y: 0 })
    .set('.hero-selection', { width: 20, height: 20 });

// ============================================
// Feature cards stagger
// ============================================
gsap.to('.feature-card', {
    scrollTrigger: {
        trigger: '.features-grid',
        start: 'top 80%',
        once: true
    },
    opacity: 1,
    y: 0,
    duration: 0.6,
    stagger: {
        amount: 0.4,
        from: 'center'
    },
    ease: 'power2.out'
});

// Feature card hover glow
document.querySelectorAll('.feature-card').forEach(card => {
    card.addEventListener('mousemove', (e) => {
        const rect = card.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        card.style.background = `radial-gradient(circle at ${x}px ${y}px, rgba(231, 76, 60, 0.08), rgba(255,255,255,0.04) 50%)`;
    });

    card.addEventListener('mouseleave', () => {
        card.style.background = '';
    });
});

// ============================================
// Steps entrance
// ============================================
gsap.to('.step', {
    scrollTrigger: {
        trigger: '.steps',
        start: 'top 80%',
        once: true
    },
    opacity: 1,
    y: 0,
    duration: 0.6,
    stagger: 0.15,
    ease: 'power2.out'
});

gsap.to('.step-connector', {
    scrollTrigger: {
        trigger: '.steps',
        start: 'top 80%',
        once: true
    },
    opacity: 1,
    duration: 0.4,
    delay: 0.3
});

// ============================================
// Download card
// ============================================
gsap.to('.download-card', {
    scrollTrigger: {
        trigger: '.download',
        start: 'top 80%',
        once: true
    },
    opacity: 1,
    y: 0,
    duration: 0.7,
    ease: 'power2.out'
});

// ============================================
// Support card
// ============================================
gsap.to('.support-card', {
    scrollTrigger: {
        trigger: '.support',
        start: 'top 85%',
        once: true
    },
    opacity: 1,
    y: 0,
    duration: 0.6,
    ease: 'power2.out'
});

// ============================================
// Magnetic button effect
// ============================================
document.querySelectorAll('.magnetic-btn').forEach(btn => {
    btn.addEventListener('mousemove', (e) => {
        const rect = btn.getBoundingClientRect();
        const x = e.clientX - rect.left - rect.width / 2;
        const y = e.clientY - rect.top - rect.height / 2;
        gsap.to(btn, {
            x: x * 0.15,
            y: y * 0.15,
            duration: 0.3,
            ease: 'power2.out'
        });
    });

    btn.addEventListener('mouseleave', () => {
        gsap.to(btn, {
            x: 0,
            y: 0,
            duration: 0.5,
            ease: 'elastic.out(1, 0.4)'
        });
    });
});

// ============================================
// Smooth anchor scroll
// ============================================
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', (e) => {
        e.preventDefault();
        const target = document.querySelector(anchor.getAttribute('href'));
        if (target) {
            gsap.to(window, {
                scrollTo: { y: target, offsetY: 80 },
                duration: 0.8,
                ease: 'power2.inOut'
            });
        }
    });
});
