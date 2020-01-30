package com.example.demo;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * HomeController
 */


@Controller
public class HomeController {

    @RequestMapping("/index")
    public String home(){

        System.out.println(123);

        return "home";
    }
}