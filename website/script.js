// ============================================
// ReplyCopilot Website JavaScript
// ============================================

// Mobile Menu Toggle
function toggleMobileMenu() {
    const nav = document.querySelector('.navbar');
    nav.classList.toggle('mobile-menu-open');
}

// Navbar Scroll Effect
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// Smooth Scroll for Anchor Links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Intersection Observer for Animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in');
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe all animated elements
document.querySelectorAll('.step, .feature-card, .use-case').forEach(el => {
    observer.observe(el);
});

// Stats Counter Animation
function animateCounter(element, target, duration = 2000) {
    let current = 0;
    const increment = target / (duration / 16);
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = target;
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(current);
        }
    }, 16);
}

// Initialize counters when they come into view
const counterObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const statNumber = entry.target.querySelector('.stat-number');
            if (statNumber && !statNumber.classList.contains('animated')) {
                statNumber.classList.add('animated');
                const text = statNumber.textContent;
                const number = parseInt(text.replace(/[^0-9]/g, ''));
                if (!isNaN(number)) {
                    animateCounter(statNumber, number);
                }
            }
            counterObserver.unobserve(entry.target);
        }
    });
}, observerOptions);

document.querySelectorAll('.stat').forEach(stat => {
    counterObserver.observe(stat);
});

// Form Validation
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// Newsletter Signup
const newsletterForm = document.querySelector('.newsletter-form');
if (newsletterForm) {
    newsletterForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const emailInput = newsletterForm.querySelector('input[type="email"]');
        const email = emailInput.value;

        if (!validateEmail(email)) {
            alert('Please enter a valid email address');
            return;
        }

        // TODO: Integrate with your email service (Mailchimp, ConvertKit, etc.)
        console.log('Newsletter signup:', email);

        // Show success message
        const successMessage = document.createElement('div');
        successMessage.className = 'success-message';
        successMessage.textContent = '✓ Thanks for subscribing!';
        newsletterForm.appendChild(successMessage);

        emailInput.value = '';

        setTimeout(() => {
            successMessage.remove();
        }, 3000);
    });
}

// Copy Code to Clipboard
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        // Show success notification
        const notification = document.createElement('div');
        notification.className = 'copy-notification';
        notification.textContent = 'Copied to clipboard!';
        document.body.appendChild(notification);

        setTimeout(() => {
            notification.remove();
        }, 2000);
    });
}

// Initialize AOS (Animate On Scroll) if available
if (typeof AOS !== 'undefined') {
    AOS.init({
        duration: 800,
        easing: 'ease-in-out',
        once: true,
        offset: 100
    });
}

// Testimonial Carousel
class TestimonialCarousel {
    constructor(container) {
        this.container = container;
        this.testimonials = container.querySelectorAll('.testimonial');
        this.currentIndex = 0;
        this.autoplayInterval = null;

        this.init();
    }

    init() {
        if (this.testimonials.length > 0) {
            this.show(0);
            this.startAutoplay();
            this.addControls();
        }
    }

    show(index) {
        this.testimonials.forEach((t, i) => {
            t.classList.toggle('active', i === index);
        });
        this.currentIndex = index;
    }

    next() {
        const nextIndex = (this.currentIndex + 1) % this.testimonials.length;
        this.show(nextIndex);
    }

    prev() {
        const prevIndex = (this.currentIndex - 1 + this.testimonials.length) % this.testimonials.length;
        this.show(prevIndex);
    }

    startAutoplay() {
        this.autoplayInterval = setInterval(() => this.next(), 5000);
    }

    stopAutoplay() {
        if (this.autoplayInterval) {
            clearInterval(this.autoplayInterval);
        }
    }

    addControls() {
        const prevBtn = this.container.querySelector('.carousel-prev');
        const nextBtn = this.container.querySelector('.carousel-next');

        if (prevBtn) {
            prevBtn.addEventListener('click', () => {
                this.prev();
                this.stopAutoplay();
                this.startAutoplay();
            });
        }

        if (nextBtn) {
            nextBtn.addEventListener('click', () => {
                this.next();
                this.stopAutoplay();
                this.startAutoplay();
            });
        }
    }
}

// Initialize carousels
document.querySelectorAll('.testimonials-carousel').forEach(carousel => {
    new TestimonialCarousel(carousel);
});

// Pricing Toggle (Monthly/Yearly)
const pricingToggle = document.querySelector('.pricing-toggle');
if (pricingToggle) {
    pricingToggle.addEventListener('click', (e) => {
        if (e.target.classList.contains('pricing-option')) {
            document.querySelectorAll('.pricing-option').forEach(opt => {
                opt.classList.remove('active');
            });
            e.target.classList.add('active');

            const isYearly = e.target.dataset.period === 'yearly';
            document.querySelectorAll('.price-amount').forEach(price => {
                const monthlyPrice = price.dataset.monthly;
                const yearlyPrice = price.dataset.yearly;
                price.textContent = isYearly ? yearlyPrice : monthlyPrice;
            });
        }
    });
}

// FAQ Accordion
document.querySelectorAll('.faq-question').forEach(question => {
    question.addEventListener('click', () => {
        const faqItem = question.parentElement;
        const isOpen = faqItem.classList.contains('open');

        // Close all other FAQs
        document.querySelectorAll('.faq-item').forEach(item => {
            item.classList.remove('open');
        });

        // Toggle current FAQ
        if (!isOpen) {
            faqItem.classList.add('open');
        }
    });
});

// Initialize tooltips
const tooltips = document.querySelectorAll('[data-tooltip]');
tooltips.forEach(element => {
    element.addEventListener('mouseenter', (e) => {
        const tooltip = document.createElement('div');
        tooltip.className = 'tooltip';
        tooltip.textContent = e.target.dataset.tooltip;
        document.body.appendChild(tooltip);

        const rect = e.target.getBoundingClientRect();
        tooltip.style.top = `${rect.top - tooltip.offsetHeight - 8}px`;
        tooltip.style.left = `${rect.left + (rect.width - tooltip.offsetWidth) / 2}px`;
    });

    element.addEventListener('mouseleave', () => {
        document.querySelectorAll('.tooltip').forEach(t => t.remove());
    });
});

// Analytics Event Tracking (Google Analytics, Mixpanel, etc.)
function trackEvent(category, action, label) {
    // Google Analytics
    if (typeof gtag !== 'undefined') {
        gtag('event', action, {
            'event_category': category,
            'event_label': label
        });
    }

    // Mixpanel
    if (typeof mixpanel !== 'undefined') {
        mixpanel.track(action, {
            category: category,
            label: label
        });
    }

    console.log('Event tracked:', category, action, label);
}

// Track button clicks
document.querySelectorAll('.btn-primary, .btn-secondary').forEach(button => {
    button.addEventListener('click', (e) => {
        const buttonText = e.target.textContent.trim();
        trackEvent('Button', 'Click', buttonText);
    });
});

// Track demo bookings
document.querySelectorAll('[onclick*="Calendly"]').forEach(button => {
    button.addEventListener('click', () => {
        trackEvent('Conversion', 'Demo Booking Clicked', 'Hero');
    });
});

console.log('✅ ReplyCopilot website initialized');
