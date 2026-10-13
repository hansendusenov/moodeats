<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */

// Public / Auth
$routes->get('/', function() {
    return session()->get('is_logged_in') ? redirect()->to('/dashboard') : redirect()->to('/login');
});

$routes->get('login', 'Auth::login');
$routes->post('login', 'Auth::attemptLogin');
$routes->get('logout', 'Auth::logout');

// Protected Backoffice Routes (Auth Filter)
$routes->group('', ['filter' => 'auth'], static function ($routes) {
    // Dashboard / Overview
    $routes->get('dashboard', 'Dashboard::index');

    // Curated Default Menus
    $routes->get('menus', 'Menus::index');
    $routes->get('menus/create', 'Menus::create');
    $routes->post('menus/store', 'Menus::store');
    $routes->get('menus/edit/(:segment)', 'Menus::edit/$1');
    $routes->post('menus/update/(:segment)', 'Menus::update/$1');
    $routes->get('menus/delete/(:segment)', 'Menus::delete/$1');
    $routes->get('menus/toggle/(:segment)', 'Menus::toggle/$1');

    // Banners & Time-Parting Ads
    $routes->get('banners', 'Banners::index');
    $routes->get('banners/create', 'Banners::create');
    $routes->post('banners/store', 'Banners::store');
    $routes->get('banners/edit/(:segment)', 'Banners::edit/$1');
    $routes->post('banners/update/(:segment)', 'Banners::update/$1');
    $routes->get('banners/delete/(:segment)', 'Banners::delete/$1');
    $routes->get('banners/toggle/(:segment)', 'Banners::toggle/$1');

    // Sponsored Merchants & Vouchers
    $routes->get('merchants', 'Merchants::index');
    $routes->get('merchants/create', 'Merchants::create');
    $routes->post('merchants/store', 'Merchants::store');
    $routes->post('merchants/bulk', 'Merchants::bulkAction');
    $routes->get('merchants/edit/(:segment)', 'Merchants::edit/$1');
    $routes->post('merchants/update/(:segment)', 'Merchants::update/$1');
    $routes->get('merchants/delete/(:segment)', 'Merchants::delete/$1');
    $routes->get('merchants/toggle/(:segment)', 'Merchants::toggle/$1');

    // Analytics & Live Sessions
    $routes->get('analytics', 'Analytics::index');

    // User Management, Ban & Voucher Injection
    $routes->get('users', 'Users::index');
    $routes->post('users/toggle-ban/(:segment)', 'Users::toggleBan/$1');
    $routes->get('users/toggle-ban/(:segment)', 'Users::toggleBan/$1');
    $routes->post('users/inject-voucher', 'Users::injectVoucher');
    $routes->get('users/vouchers/(:segment)', 'Users::userVouchers/$1');
    $routes->get('users/revoke-voucher/(:segment)', 'Users::revokeVoucher/$1');
    $routes->get('users/delete/(:segment)', 'Users::delete/$1');
});
